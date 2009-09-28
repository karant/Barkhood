class Blog < ActiveRecord::Base
  attr_protected :owner_id, :owner_type
    
  belongs_to :owner, :polymorphic => true
  has_many :posts, :order => "created_at DESC", :dependent => :destroy,
                   :class_name => "BlogPost"
                   
  def person
    dog.owner
  end
  
  def dog
    @dog ||= case owner.class.to_s
                   when "Dog"
                     owner
                   when "Group"
                     owner.owner
                   end
  end
end
