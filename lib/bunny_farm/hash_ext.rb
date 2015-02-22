require 'active_support/core_ext/hash/keys'

class Hash

  # Extract a limited set of keys from a hash
  # SMELL: this will mess up on hash entires that are arrays of hashes.
  def tdv_extract(an_array)
    temp_hash = {}
    an_array.each do |s|
      if s.is_a? Symbol
        temp_hash[s] = self[s]
      elsif s.is_a? Hash
        # FIXME: Why don't we allow all the keys?
        the_entry_name = s.keys.first
        the_component_names = s[the_entry_name]
        if self[the_entry_name].is_a? Hash
          temp_hash[the_entry_name] = self[the_entry_name].tdv_extract(the_component_names)
        elsif self[the_entry_name].is_a? Array
          temp_hash[the_entry_name] = []
          self[the_entry_name].each do |a|
            temp_hash[the_entry_name] << a.tdv_extract(the_component_names)
          end
        elsif self[the_entry_name].is_a? NilClass
          next
        else
          raise "Another Invalid entry #{the_entry_name} of #{self[the_entry_name].class}"
        end
      else
        raise "Invalid entry name #{s} of class #{s.class}"
      end
    end
    return temp_hash
  end

end # class Hash


