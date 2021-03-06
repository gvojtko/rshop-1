# coding: utf-8

class Order < ActiveRecord::Base

  CART      = 0
  WAITING   = 1
  NOT_PAID  = 2
  PAID      = 3
  SENT      = 4
  FINISHED  = 5

  STATES = ['Košík', 'Přijato', 'Nezaplaceno', 'Zaplaceno', 'Odesláno', 'Hotovo']
  SYM_STATES = [:cart, :waiting, :not_paid, :paid, :sent, :finished]

  # relations
  belongs_to :payment_method
  belongs_to :customer
  accepts_nested_attributes_for :customer

  has_many :items,  -> { includes :product }
  accepts_nested_attributes_for :items, :allow_destroy => true
  has_many :products, :through => :items #, -> { uniq }
  accepts_nested_attributes_for :products
  has_many :invoices
  has_one  :invoice_address, :dependent => :destroy
  accepts_nested_attributes_for :invoice_address

  # attributes validation
  validates_presence_of :sum, :state
  validates_presence_of :payment_method_id, :unless => :cart?

  before_validation :set_defaults

  attr_accessible :message, :payment_method_id, :items_attributes

  # behavior of pagination
  cattr_reader :order_page
  @@per_page = 5
  default_scope { order('id DESC') }

  scope :finished_by, lambda {|cid|
    includes(:employee).where(:state => FINISHED, :customer_id => cid) }

  scope :waiting,    -> { includes(:customer).where("state != #{FINISHED} AND state != #{CART}") }

  scope :finished,   -> { includes(:customer).where(:state => FINISHED) }

  scope :not_paid,   -> { includes(:customer).where(:state => NOT_PAID) }

  scope :cart,  -> {  includes(:customer).where(:state => CART) }

  scope :paid,  -> { includes(:customer).where(:state => PAID) }

  scope :sent,  -> { includes(:customer).where(:state => SENT) }

  scope :by_state, lambda {|state|
     includes(:customer).where(:state => state) }

  scope :finished_in_month, lambda {|month|
    where("state = #{Order::FINISHED} AND created_at >= :begin AND created_at <= :end", { :begin => month, :end => month.end_of_month })}


  def cart?
    self.state == CART
  end

  def finished?
    self.state == FINISHED
  end

  def self.state_options
    options = []
    STATES.each_with_index { |s,i| options << [s, i] if i >0 }
    options
  end

  def self.monthly_products(month)
    orders = Order.finished_in_month month
    all_items = orders.collect{|o|
      o.items
    }
    products = all_items.flatten.inject(Hash.new(0)){ |h,item|
      h[item.product] += item.amount; h
    }
    products.sort_by{|k,v|-v }
  end

  def state_in_words
    STATES[self.state]
  end

  def next_state
    STATES[self.state < FINISHED ? self.state+1 : FINISHED]
  end

  def set_next_state
    self.increment! :state if self.state < FINISHED
  end

  def state_as_symbol
    SYM_STATES[self.state]
  end

  def pm_name
    self.payment_method.name
  rescue
    ''
  end

  def remove_all_items
    self.items.delete_all
    self.update_attribute :sum, 0
  end

  def update_item(product, amount)
    item = product.items.in self
    item.count = amount
    item.cost = product.price * amount
    actualize_sum
    return item.cost
  end

  def add_item(product, amount=1)
   item = product.items.in self
   if item == nil
     item = self.items.create(
        :count=>amount, :cost=>product.price*amount, :product=>product
     )
   else
     item.count += amount
     item.cost = product.price * item.count
     item.save
   end
   actualize_sum
   return item.cost
  end

  def actualize_sum
    sum = self.items.inject(0) { |sum, i| sum + i.cost }
    self.update_attribute :sum, sum
  end

  def submit(params)
    self.message = params[:message]
    self.payment_method_id = params[:payment_method_id]
    self.state = WAITING
    if self.save
      self.products { |p|
        begin
          p.increment! :counter
          p.decrement! :amount if p.amount > 0
        rescue
          next
        end
      }
      true
    else
      self.state = CART
      false
    end
  end

  def invoice_address?
    self.invoice_address.id ? true : false
  rescue
    false
  end

  def update_invoice_address(attributes)
    is_empty = true
    attributes.each do |a|
      unless a.blank?
        is_empty = false
        return
      end
    end
    if invoice_address?
      if is_empty
        self.invoice_address.delete
        self.build_invoice_address
      else
        self.invoice_address.update_attributes attributes
      end
    else
      if is_empty
        self.build_invoice_address
      else
        self.create_invoice_address(attributes)
      end
    end
    return is_empty
  end

protected

  def set_defaults
    self.sum = 0 unless self.sum
    self.state = CART unless self.state
  end

end
