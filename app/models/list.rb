class List
    include Mongoid::Document
    include Mongoid::Timestamps

    field :title, type: String
    field :order, type: Integer, default: 0

    belongs_to :project
    has_many :tasks, dependent: :destroy

    validates :title, presence: true
end