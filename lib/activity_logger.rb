module ActivityLogger

  # Add an activity to the feeds of a person's contacts.
  # Usually, we only add to the feeds of the contacts, not the person himself.
  # For example, if a person makes a forum post, the activity shows up in
  # his contacts' feeds but not his.
  # The :include_dog option is to handle the case when add_activities
  # should include the dog as well.  This happens when
  # someone comments on a dog's blog post or wall.  In that case, when
  # adding activities to the contacts of the wall's or post's owner,
  # we should include the owner as well, so that he sees in his feed
  # that a comment has been made.
  def add_activities(options = {})
    dog = options[:dog]
    include_dog = options[:include_dog]
    activity = options[:activity] ||
               Activity.create!(:item => options[:item], :dog => dog)
    
    dogs_and_owners_ids = dogs_to_add(dog, activity, include_dog)
    do_feed_insert(dogs_and_owners_ids, activity.id) unless dogs_and_owners_ids.empty?
  end
  
  private
  
    # Return the ids of the dogs whose feeds need to be updated and ids of their owners.
    # The key step is the subtraction of dogs who already have the activity.
    def dogs_to_add(dog, activity, include_dog)
      all = dog.contacts.reject{|c| c.owner_id == dog.owner_id}.map{|d| [d.id, d.owner_id]}
      dog.owner.dogs.each do |owners_dog|
        all.push([owners_dog.id, owners_dog.owner_id]) 
      end if include_dog
      all - already_have_activity(all, activity)
    end
  
    # Return the ids of dogs who already have the given feed activity.
    # The results of the query are Feed objects with only a dog_id
    # attribute (due to the "DISTINCT dog_id" clause), which we extract
    # using map(&:dog_id).
    def already_have_activity(dogs, activity)
      Feed.find(:all, :select => "DISTINCT dog_id",
                      :conditions => ["dog_id IN (?) AND activity_id = ?",
                                      dogs, activity]).map{|f| [f.dog_id, f.person_id]}    
    end
  
    # Return the SQL values string needed for the SQL VALUES clause.
    # Arguments: an array of ids and a common value to be inserted for each.
    # E.g., values([1, 3, 4], 17) returns "(1, 17), (3, 17), (4, 17)"
    def values(ids, common_value)
      common_values = [common_value] * ids.length
      convert_to_sql(ids.zip(common_values).each(&:flatten!))
    end

    # Convert an array of values into an SQL string.
    # For example, [[1, 2], [3, 4]] becomes "(1,2), (3, 4)".
    # This does no escaping since it currently only needs to work with ints.
    def convert_to_sql(array_of_values)
      array_of_values.inspect[1...-1].gsub('[', '(').gsub(']', ')')
    end
  
    def do_feed_insert(dog_ids, activity_id)
      sql = %(INSERT INTO feeds (dog_id, person_id, activity_id) 
              VALUES #{values(dog_ids, activity_id)})
      ActiveRecord::Base.connection.execute(sql)
    end
end