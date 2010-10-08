# -*- coding: utf-8 -*-

require File.expand_path(File.join('.', 'spec_helper'), File.dirname(__FILE__))
require 'pp' # for lib/sample.rb
require 'rask' # for lib/sample.rb

COUNT      = 100

#Rask.enable_thread

module Test
  class TestTask < Rask::Task
    
    attr_accessor :data
    define_state :start,   :initial => true
    define_state :running
    define_state :finish,  :from    => [:running]
    
    def start
      print "Group[#{self.group}] get started. \n"
      transition_to_running
    end
    
    def running
      print "."
      data[:finish_count] -= 1
      transition_to_finish if data[:finish_count]<=0
    end
    
    def finish
      print "Group[#{self.group}] finished. \n"
      destroy
    end
  end
  
  class RaisingTask < Rask::Task
    
    define_state :start,   :initial => true
    define_state :running
    define_state :finish,  :from    => [:running]
    
    def start
      print "Group[#{self.group}] get started. \n"
      transition_to_running
    end
    
    def running
      print "."
      transition_to_finish
      raise 'Something wrong!!!!'
    end
    
    def finish
      print "Group[#{self.group}] finished. \n"
      destroy
    end
  end
end


describe Rask, "When create" do
  before(:each) do
    Rask.base_directory = '/tmp/rask/test'
    Rask.initialize_storage
  end

  it "Suspended Directory" do
    File.exist?(Rask.base_directory+"/suspended").should == true
  end
  
  it "Tutorial" do
    10.times {
      task = Test::TestTask.new
      task.data = { :test=>'test of Task', :finish_count => COUNT }
      Rask.insert task
    }
    
    Rask.task_ids.each { |task_id|
      Rask.run(task_id) { |task|
        task.state.should == :start
        task.run
      }
      COUNT.times {
        Rask.run(task_id) { |task|
          task.state.should == :running
          task.run
        }
      }
      Rask.run(task_id) { |task|
        task.state.should == :finish
        task.run
      }
    }
    Rask.task_ids.length.should == 0
  end

  it "Group" do
    5.times {
      task = Test::TestTask.new('group_id')
      task.data = { :test=>'test of Task', :finish_count => COUNT }
      Rask.insert task
    }
    3.times {
      task = Test::TestTask.new(1)
      task.data = { :test=>'test of Task', :finish_count => COUNT }
      Rask.insert task
    }
    Rask.task_ids(:group=>'group_id').length.should == 5
    Rask.task_ids(:group=>1).length.should == 3
    
    Rask.task_ids(:group=>'group_id').each { |task_id|
      Rask.run(task_id) { |task|
        task.state.should == :start
        task.run
      }
      COUNT.times {
        Rask.run(task_id) { |task|
          task.state.should == :running
          task.run
        }
      }
      Rask.run(task_id) { |task|
        task.state.should == :finish
        task.run
      }
    }
    Rask.task_ids(:group=>'group_id').length.should == 0
    Rask.task_ids(:group=>1).length.should == 3
    
    Rask.task_ids(:group=>1).each { |task_id|
      Rask.run(task_id) { |task|
        task.state.should == :start
        task.run
      }
      COUNT.times {
        Rask.run(task_id) { |task|
          task.state.should == :running
          task.run
        }
      }
      Rask.run(task_id) { |task|
        task.state.should == :finish
        task.run
      }
    }
    Rask.task_ids(:group=>'group_id').length.should == 0
    Rask.task_ids(:group=>1).length.should == 0
  end
  
  it "Base Directory" do
    backup = Rask.base_directory
    Rask.base_directory = "hogehoge"
    Rask.base_directory.should == "hogehoge"
    Rask.base_directory = backup
    Rask.base_directory.should == backup
  end
  
  it "Daemon Safety" do
    Rask.insert Test::RaisingTask.new
    begin
      task_list = Rask.task_ids
      p task_list
      task_list.each { |task_id|
        Rask.run(task_id) { |task|
          task.run
          File.exist?(Rask.base_directory+"/suspended/"+task_id.task).should == true
        }
      }
    end while task_list.length > 0
  end
  
  after(:each) do
    FileUtils.rm_r Dir.glob(Rask.base_directory+'/*')
  end
end
