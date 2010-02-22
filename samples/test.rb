require 'rubygems'
require 'rask'
#
# 数値のカウントアップ 10 までカウントする
# タスクの定義
#
class CountupTask < Rask::Task
  define_state :start,   :initial => true       # 初期状態
  define_state :running                         # 実行
  define_state :finish,  :from    => [:running] # 終了 (遷移元は:runningからのみ)
  
  def start
    @count = 0
    p "start"
    transition_to_running # :running へ遷移
  end
  
  def running
    p "running count => #{@count+=1}"
    transition_to_finish if @count>=10 # :finish へ遷移
  end
  
  def finish
    p "finished"
    destroy # タスクの破棄
  end
end


# タスクを動かす
task = CountupTask.new # タスクの作成
Rask.insert task       # タスクの登録

# バックグラウンドタスクの実行
Rask.daemon
