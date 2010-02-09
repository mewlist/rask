#
# Rask
# StateMachinelibrary
# (c)2010 mewlist
#
require 'thread'



module Rask
  
  module StateMachine
    attr_accessor :state
    
    
    def initialize
      @state = initial_state
    end
    
    
    def initial_state
      nil
    end
    
    
    def transition(to)
      @state = to
    end
    
    
    def destroy
      transition nil
    end
    
    
    def destroy?
      @state == nil
    end
    
    
    
    
    
    
    
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    
    
    
    
    
    module ClassMethods
      def define_state(name, *args)
        
        self.instance_eval{
          define_method(name){
          }
          define_method("transition_to_#{name}"){
            if args[0].is_a?(Hash)
              self.state = name if args[0][:from] && args[0][:from].include?(state)
            else
              self.state = name
            end
          }
          define_method("#{name}?"){
            self.state == name
          }
          if !method_defined?(name) || ( args[0].is_a?(Hash) && args[0][:initial] )
            define_method("initial_state") {
              name
            }
          end
        }
      end
    end
  end
  
  
  
  
end





