class Book < ActiveRecord::Base
  paginates_per 15
  acts_as_taggable

  validates :title, presence: true
  validates :author, presence: true

  mount_uploader :cover, CoverUploader
  mount_uploader :document, DocumentUploader

  scope :alphabetically, -> { order(:title)  }
  scope :added, -> { order(created_at: :desc) }
  scope :published, -> { order(publish_year: :desc) }
  scope :favorites, -> { order(:author) }

  def link
    if document?
      document.url
    else
      self.url
    end
  end
end
