class Task
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :description, type: String
  field :completed, type: Boolean, default: false
  field :progress, type: Integer, default: 0
  field :due_date, type: DateTime
  field :comments, type: Array, default: []

  belongs_to :list


  validates :title, presence: true


end
