module CertPub

  module Util

    # Loads a module/class using a string representation of its name
    # https://stackoverflow.com/a/3163713/135001
    def self.impl(str)
      str.split('::').inject(Object) do |mod, class_name|
        mod.const_get(class_name)
      end
    end

  end

end