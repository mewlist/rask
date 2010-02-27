#
# Rask library
# (c)2010 mewlist
#
require 'fileutils'
require 'thread'

require File.dirname(__FILE__) + '/rask/state_machine'

#Authors::   mewlist / Hidenori Doi
#Copyright:: Copyright (C) 2010 mewlist / Hidenori Doi
#License::   The MIT License
#
#== Rask is terminatable task engine
#
module Rask
  
  #
  #===Task base class
  #To define new Task you must inherit this base-class
  #* sample code
  # class NewTask < Rask::Task
  #   define_state :initial, :initial => true
  #   define_state :finish
  #   def initial
  #     transition :finish
  #   end
  #   def finish
  #     destroy
  #   end
  # end
  class Task
    include StateMachine
    attr_accessor :task_id
    attr_accessor :group
    attr_reader   :state
    
    #
    #====If group option is given, the task is classified by group name.
    #
    #==== _group
    # group name to classify
    def initialize(_group=nil)
      self.group = _group
      super()
    end
    
    #
    #====automatically callbacked from task engine.
    #
    def run
      if @state
        eval @state.to_s
      end
    end
    
    #
    #====Transition to new state. In the state function.
    # Usually you should call generated transition_to_[state name] function
    def transition(to)
      @state = to
    end
    
    
    #
    def destroy
      transition nil
    end
    
    #
    def destroy?
      @state == nil
    end
    
  end
  
  
  @@base_dir         = '/tmp/rask'
  @@thread_max_count = 5
  @@thread_count     = 0
  @@terminated       = false
  @@queue            = Queue.new
  @@processing       = []
  @@locker           = Mutex::new
  
  #
  #====Set base storage directory
  #default is '/tmp/rask'
  #
  def self.base_directory=(new_directory)
    @@base_dir = new_directory
  end
  
  #
  #====Set max count of worker thread
  #
  def self.thread_max_count=(count)
    @@thread_max_count = count
  end
  
  #
  def self.task_path(task_id)
    @@base_dir+"/#{task_id}.task"
  end
  
  #
  def self.pid_path
    @@base_dir+"/#{File.basename($0)}.pid"
  end
  
  #
  #====Insert new task 
  # Rask::insert NewTask.new
  def self.insert(task)
    initialize_storage
    task_id = "#{safe_class_name(task.class.name)}-#{task.group.to_s}-#{Time.now.to_i}-#{Time.now.usec}"
    task.task_id = task_id
    FileUtils.touch(task_path(task_id)) unless File.exists? task_path(task_id)
    f = File.open(task_path(task_id), 'w')
    f.flock(File::LOCK_EX)
    Marshal.dump(task, f)
    f.flock(File::LOCK_UN)
    f.close
  end
  
  
  #
  def self.run(task_id)
    f = File.open(task_path(task_id), 'r+') rescue return
    f.flock(File::LOCK_EX)
    
    task = Marshal.restore(f)
    yield task
    
    f.truncate(0)
    f.pos = 0
    Marshal.dump(task, f)
    f.flock(File::LOCK_UN)
    f.close
    FileUtils.rm(task_path(task_id)) if task.destroy?
  end
  
  #
  def self.read(task_id)
    f = File.open(task_path(task_id), 'r+') rescue return
    f.flock(File::LOCK_EX)
    task = Marshal.restore(f)
    f.flock(File::LOCK_UN)
    f.close
    task
  end
  
  #
  #====Get all file path of task list
  #
  def self.task_ids(options = { :class=>nil, :group=>nil })
    target = @@base_dir
    target += '/'
    if options[:class]
      target += "#{safe_class_name(options[:class])}"
    else
      target += "[^-]+"
    end
    target += "-#{options[:group]}-" if options[:group]
    
    task_id_list = []
    Dir.glob(@@base_dir+"/*.task") { |d|
      if target.empty? || /#{target}/ =~ d
        task_id_list.push File.basename(d, ".*")
      end
    }
    task_id_list
  end
  
  #
  def self.initialize_storage
    unless File.exists? @@base_dir
      FileUtils.makedirs @@base_dir
    end
  end
  
  #
  #====force destroy the task
  #
  def self.destroy(task)
    FileUtils.rm(task_path(task.task_id)) if File.exists? task_path(task.task_id)
  end
  
  #
  def self.safe_class_name(c)
    c.gsub(/[:]/,'@')
  end
  
  #
  #====Start daemon process
  #It is possible to specify the the task group.
  # Rask.daemon(:group=>'TaskGroup')
  #
  def self.daemon(options = {})
    options = { :sleep=>0.1 }.merge(options)
    print "daemon start\n"
    exit if fork
    Process.setsid
    if File.exist? pid_path
      print "already running rask process. #{File.basename($0)}"
      return
    end
    open(pid_path,"w"){|f| f.write Process.pid}
    
    # create worker threads
    threads = []
    for i in 1..@@thread_max_count do 
      threads << Thread::new(i) { |thread_id|
        @@thread_count += 1
        while !@@terminated
          d = nil
          @@locker.synchronize do
            d = @@queue.pop unless @@queue.empty?
          end
          if d != nil
#            print "#{d}\n"
            run(d) { |task| task.run }
            @@locker.synchronize do
              @@processing.delete(d)
            end
          else
#            print "no data in queue\n"
            sleep(options[:sleep])
          end
        end
        print "#{thread_id}"
        @@thread_count -= 1
      }
    end
    
    Signal.trap(:TERM) {safe_exit}
    
    while true
      task_list = Rask.task_ids(options)
      task_list.each { |d|
        @@locker.synchronize do
          unless @@processing.include?(d)
            @@queue.push d
            @@processing.push d
          end
        end
      }
      sleep(options[:sleep])
    end
  end
  
  #
  def self.safe_exit
    print "daemon terminated"
    @@terminated = true
    while @@thread_count > 0
      sleep(0.1)
    end
    FileUtils.rm(pid_path) if File.exist?(pid_path)
    print "done \n"
    exit
  end
  
end

