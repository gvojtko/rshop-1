require "open-uri"

class Product < ActiveRecord::Base
  extend FriendlyId

  acts_as_list

  # relations
  belongs_to :category
  belongs_to :supplier

  has_many :orders, :through => :items
  has_many :items do
    def in(order)
      item = find_by_order_id order.id
    end
  end

  has_many :supplies, :through => :entries

  friendly_id :title, :use => :slugged #, :approximate_ascii => true

  # picture
  has_attached_file :picture,
  :url => "/pictures/:id/:style_:basename.:extension",
  :path => ":rails_root/public/pictures/:id/:style_:basename.:extension",
  :default_url => "/pictures/:style_default.png",
  :default_style => :large,
  :web_root => '/pictures/', :storage => :filesystem,
                           :styles => { :square  => "112x112>",
                                        :large => "320x320>"}
  attr_protected :picture_file_name,
                 :picture_content_type,
                 :picture_size,
                 :picture_updated_at
  attr_accessor  :picture_url
  alias_attribute :name, :title
  # attributes validation
  validates_presence_of :title, :price, :amount
  validates_numericality_of :price,  :greater_than_or_equal_to => 0
  #validates_numericality_of :amount, :greater_than_or_equal_to => 0

  validates_attachment_content_type :picture, :unless => :before_new,
  :content_type => ['image/jpeg', 'image/pjpeg', 'image/jpg',  'image/png']

  # behavior of pagination
  cattr_reader :per_page
  @@per_page = 10
  default_scope :order => 'position ASC'

  scope :active,
    includes(:category).where(:active => 1)

  scope :newest,
    includes(:category).where(:active => 1).order('id DESC')

  def before_new; true; end

  def available?
    self.amount != 0 ? true : false
  end

  def full_description
    self.description.html_safe # TODO
  end

  def picture_from_url(url)
    self.picture = open(url)
  end

end
