class AllDog < Dog
  is_indexed :fields => [ 'name', 'description'],
             :include => [
               {:association_name => 'breed', :field => 'name', :as => 'breed_name'}
             ]
end