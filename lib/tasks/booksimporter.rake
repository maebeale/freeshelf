#require 'models/freebooksimporter.rb'

namespace :books do                             #TODO create cron on heroku for regularly scheduled refreshes of data
  desc 'Rake task to get books file from web'
  task :getlivefile => :environment do
    open('https://raw.githubusercontent.com/vhf/free-programming-books/master/free-programming-books.md',
         'User-Agent' => 'freeshelf_app') do |free_books|
      @free_books = free_books
      #overwrite local file
    end                                        #TODO ck it out: http://stackoverflow.com/questions/577944/how-to-run-rake-tasks-from-within-rake-tasks
  end

  desc 'Rake task to get local books file'
  task :getlocalfile => :environment do
    @free_books = File.open(File.join('lib/assets', 'freeprogrammingbooks.md'),'r')
  end

  desc 'Rake task to parse books file'
  task :parse => :environment do
    @free_books.each_line do |line|
      #parse_line(line) #TODO figure out how to call this from another location. eg. models
      def parse_line(line)
        if line =~  /^[#]{2,}.* /x  ||             #TODO add ignore Index line?
            line =~ /^[\s]{0,}[\*]{0,}+[\s]{0,}+[\*]{1,}+[\s]{1,}+(?!\[).*/
          /[ [[#]*][[\s]*[\*]{1}+[\s]+]]+/.match(line)
          @tag_name = match_data[1]                #TODO check on quantifiers & +* syntax in sequences
          @processed -= 1
        elsif line =~ /^.*[\[]+.*[\]]+[\s]{0,}+[\(](?!#).*/
          /[.]*[\[\]]/.match(line)
          binding.pry
          @title = match_data[1]
          /[[\]] [\(] [\)*]]/.(match_data[2])
          @url = match_data[1]
          /[\s]+[-]{1}+[\s]+(?=[\w])/.match(match_data[2])
          /[\s]+[Bb]y+[\s]+(?=[\w])/.match(match_data[2])
          /[\s]*[\]\)\(\*]+/.match(match_data[2])
          (/^\w(?=[\\n])+/ || /^.*[\\n]+/).match(match_data[2])
          @creator = match_data[2]                  #TODO fix creators, e.g."," "||" & others, like edge case creators, e.g.  2.x. Eric Ligman
        elsif line =~ /^[\s].*/
          @processed -= 1
        else
          @processed -= 1
        end
      end
      @saved = 1
      @processed = 1
      puts "***#{@title}.\t\t(#{@url}).\n\t\t\ttag(s): #{@tag_name} \t\t\t\t\tby: #{@creator}***"
    end
    puts '---------------------------------------'
    puts "Found #{@saved}/#{@processed} books. Denied #{@denied} books."
    puts '---------------------------------------'
  end

  desc 'Rake task to process books data in the db'
  task :import => :environment do
    conn = ActiveRecord::Base.connection
    @processed +=1
    #tag_list =                                    #TODO make tag_list an array.add subheadings as 2nd tag. db dupe as 2nd tag? use the "See..." lines as addtl tags?
    attrs = :title, :url, :tag, :creator, :slug, :tag_list, :tag_name
    unless Book.find_by_url(@url)                  #TODO this assumes one url/book, but might not be true?
      if @creator =~ /[[:space:]]/ || @creator == "s))\n"  #TODO find better match for edge case (Clipper Tutorial)
        @book = Book.create(title: "#{@title}",
                            url: "#{@url}",
                            creator:  "unknown",
                            tag_list: "#{@tag_name}")
      else
        @book = Book.create(title: "#{@title}",
                            url: "#{@url}",
                            creator: "#{@creator}",
                            tag_list: "#{@tag_name}")
      end
      if @book.creator =~ /^[\s]*[\-\.\*\,\|].*/ || @book.creator =~ /^[\s]*[\d\-\.\*\,].*/
        puts "*********Check book below. Creator info may not have imported correctly.*********"
                                                  #TODO create non-inline list of odd creator info.
        @denied += 1
      end
      puts "New book ##{@saved}: #{@book.title}"
      puts "\t\t(#{@book.url}).\n\t\t\ttag(s): #{@book.tag_list} \t\t\t\t\tby: #{@book.creator}"
      @book.save!
      @saved += 1
    else
      puts "***Book below did not import: either was already in the database, or your file has dupe urls.***"
      puts "***#{@title}.\t\t(#{@url}).\n\t\t\ttag(s): #{@tag_name} \t\t\t\t\tby: #{@creator}***"
    end
    puts '---------------------------------------'
    puts "Added #{@saved}/#{@processed} books. Denied #{@denied} books."
    puts '---------------------------------------'
  end
#TODO figure out what the favorites error was on the autopopulated tags
#TODO Add extra end at end of file if using live file

  desc "Access, parse & import books data into freeshelf db"
  task :importfromlive => [:getlivefile, :parse, :import] do
  end

  desc "Access, parse & import books data into freeshelf db"
  task :importfromlocal => [:getlocalfile, :parse, :import] do
  end

  desc "Access, parse & import books data into freeshelf db"
  task :testparserlocal => [:getlocalfile, :parse] do
  end


end
