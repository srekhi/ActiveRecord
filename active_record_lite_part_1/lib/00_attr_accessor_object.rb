class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |inst_var|
      define_method(inst_var) { self.instance_variable_get("@#{inst_var}") }
      define_method("#{inst_var}=") { |set_val| self.instance_variable_set("@#{inst_var}", set_val) }
    end
  end
end
