# $Revision:0.1$
# rating.rb: 複数軸による記事評価とグラフ表示
# for tDiary
#
# 使い方
# そのまま plugin ディレクトリに置きます。
# '設定' -> 'rating.rb Configuration' で、評価軸や
# 表示内容を設定。
# くわしくは 
# http://www.maripo.jp/diary/?date=20071019
#
# Copyright (c) 2007 Mariko/Maripo GODA <god@maripo.jp>
# http://www.maripo.jp/
# You can redistribute it and/or modify it under GPL.


require 'pstore'
require 'cgi'
@dbase = "#{@cache_path}/rating.db"

#########################################
# Config (Form)
#########################################

add_conf_proc('rating', 'rating.rb Configuration') do
    rating_config = RatingConfig.new(@dbase)
    form_string = ""

      if @mode == 'saveconf'

        # save conf
        index = 0

        # edit axes
        rating_config.each { |axis_config|
            #check values
            if (@cgi.params["label" + index.to_s][0] != "" && (@cgi.params["range" + index.to_s][0]).to_i > 0)
                axis_config.edit(@cgi.params["label" + index.to_s][0], @cgi.params["label_max" + index.to_s][0],@cgi.params["label_min" + index.to_s][0],@cgi.params["range" + index.to_s][0].to_i,@cgi.params["order" + index.to_s][0].to_i,@cgi.params["display" + index.to_s][0]!=nil)
                index += 1
            end
        }
        if (@cgi.params["label_new"][0] != "" && @cgi.params["range_new"][0].to_i > 0)
            # add new axis
            rating_config.add_axis(@cgi.params["label_new"][0], @cgi.params["label_max_new"][0], @cgi.params["label_min_new"][0], @cgi.params["range_new"][0].to_i)
        end
        rating_config.save_to_db

    end

    # print conf form

    form_string += <<HTML
<p>
フィードバックフォームの設定をします。軸はいくつでも作成することができます。
</p>
<p>
<a href="http://www.maripo.jp/">作者</a>の <a href="http://www.maripo.jp/diary/?date=20071019">blog</a> に追加情報が書いてあるかもしれません。
</p>
<h3>設定方法</h3>
<ul>
<li>順 … 表示される順番です。小さいほうから順に並びます。番号が飛んでもOK。</li>
<li>表示 … いらない軸はチェックを外してしまってください。
<li>軸の名前 … (例) "この記事は参考になりましたか"</li>
<li>最低ラベル … 例 "まったく参考にならない"</li>
<li>最高ラベル … 例 "とても参考になった"</li>
<li>選択肢数 … 例 : 1〜5の5段階なら "5"</li>
</p>
<h3>設定内容</h3>
<form>
<table>
HTML
    index = 0;

    rating_config.each { |axis_config|
        form_string += <<HTML
<tr>
<td>順:<input type="text" size="2" name="order#{index}" value="#{axis_config.order}"></td>
<td>
軸の名前:<input type="text" size="16" name="label#{index}" value="#{axis_config.label}">　
最低ラベル:<input type="text" size="10" name="label_min#{index}" value="#{axis_config.label_min}">　
最高ラベル:<input type="text" size="10" name="label_max#{index}" value="#{axis_config.label_max}">　
選択肢数:<input type="text" size="4" name="range#{index}" value="#{axis_config.range.to_s}">　
表示:<input type="checkbox" name="display#{index}" value="#{axis_config.label_max}" #{axis_config.check_label}>
</td>
</tr>
HTML
        index += 1
    }
    form_string += <<HTML
<tr>
<td>追加</td>
<td>
軸の名前:<input type="text" size="16" name="label_new"> 
最低ラベル:<input type="text" size="10" name="label_min_new"> 
最高ラベル:<input type="text" size="10" name="label_max_new"> 
選択肢数:<input type="text" size="4" name="range_new">
</td>
</tr>
</table>
HTML
        form_string += '</form>'
        form_string #evaluate
    end


#########################################
# Entry of the day
#########################################

add_body_leave_proc do |date|
    graph_string = ""
    form_string = ""
    contentString = ""

    #initialize DateEval object
    todays_eval = DateEval.new(date.strftime('%Y%m%d'), @dbase)

    #initialize RatingConfig object
    @rating_config = RatingConfig.new(@dbase)

    graph_string += <<HTML
<!-- Generated by plugin "rating.rb" -->
<div  class="ratingGraphContainer" style="overflow:hidden;height:18px;">
<div
onclick="with(this.parentNode.style){if(overflow=='hidden'){overflow='visible';}else{overflow='hidden';}}"
style="cursor:hand;"
class="ratingGraphOpener">
[分布をみる]
</div>
<div class="ratingGraphContent">
HTML
    form_string += '<!-- Generated by plugin "rating.rb" -->' + "\n"
    form_string += ('<form action="./"><input type="hidden" name="comment" value="submit"><input type="hidden" name="body" value="rating"><input type="hidden" name="body" value="rating"><input type="hidden" name="name" value=""><input type="hidden" value="' + date.strftime('%Y%m%d') + '"><div class="ratingForm">')
    @rating_config.each{|axis_config|

        if !axis_config.display 
            next
        end

        # add axis info
        form_string += ('<div class="ratingQuestion"><span class="ratingLabel">' + axis_config.label + '</span>')
        
        # add radio buttons
        form_string += ('<span class="ratingRadioButtons"><span class="ratingLabelMin">' + axis_config.label_min + '</span>')

        # append graph string
        current_rank = 0

        graph_string += '<div class="ratingGraphBox">' #begin "graphBox"
        graph_string += '<span class="ratingGraphAverage">average : ' +  sprintf("%10.2f", todays_eval.get_average(axis_config.id)) +'</span><br>'
        while current_rank < axis_config.range
            graph_string += ('<div style="clear:both"><div
class="ratingGraphRank">' + (current_rank + 1).to_s + '</div><div
class="ratingGraphBar" style="width:' +
todays_eval.get_graph_length(axis_config.id, current_rank).to_s +
'px"></div><span class="ratingGraphValue"> (' + todays_eval.get_value(axis_config.id, current_rank).to_s + '票)</span></div>')
            current_rank += 1
        end
        graph_string += '</div>' #end "graphBox"

        for current_rank in 0..axis_config.range - 1
            form_string += " " + '<input type="radio" name="axis' + axis_config.id.to_s + '" value="' + current_rank.to_s + '">' + (current_rank + 1).to_s
        end
        form_string += ('<span class="ratingLabelMax">' + axis_config.label_max + '</span></span>')
        form_string += '</div>'
    }
    graph_string += <<HTML
</div>
</div>
<div style="clear:both;height:0px;"></div>
HTML
    form_string += '<input type="hidden" name="date" value="' + date.strftime('%Y%m%d') + '">'
    form_string += '<input type="submit" value="評価する"></div></form>'+"\n"
    (form_string + graph_string)

end

#########################################
# class RatingConfig
#########################################

class RatingConfig
    @axes
    @max_axis_id= 0
    @dbase

    def initialize (dbase)
        @dbase = dbase
        db = PStore.new(@dbase)
        db.transaction do
            #begin transaction
            if db.root?("config")
                @axes = Hash.new
                obj = db["config"]
                @max_axis_id = obj[0]
                obj.each{|ary|
                    id = ary[4]
                    @axes[id] = AxisConfig.new(ary[0],ary[1],ary[2],ary[3],ary[4],ary[5],ary[6])
                }
            else
                @axes = Hash.new
                @max_axis_id = 0
            end
        end
        #end transaction
    end #end initialize

    def save_to_db
        save_array = Array.new
        db = PStore.new(@dbase)
        save_array.push(@max_axis_id)
        each {|axis_config|
            save_array.push(axis_config.to_array)
        }
        db.transaction do
            #begin transaction
            db["config"] = save_array
        end
        #end transaction
    end #end save_to_db

    def add_axis (label, label_max, label_min, range)
        @max_axis_id += 1
        new_axis = AxisConfig.new(label, label_max, label_min, range, @max_axis_id, 0, true)
        @axes[@max_axis_id] = new_axis
    end #end add_axis

    def edit_axis (axis_id, label, label_max, label_min, range, order,display)
        target_axis = @axes[axis_id]
        target_axis.edit(label, label_max, label_min, range, order,display)
    end

    def length
        return @axes.size
    end #end length

    def each
        @axes.to_a.sort {|a, b| a[1].order <=> b[1].order}.each {|key ,axis_conf|
            yield axis_conf
        }
    end #end each
end

#########################################
# class AxisConfig
#########################################

class AxisConfig
    @label
    @label_max
    @label_min
    @range
    @id
    @order
    @display = true
    
    #accessors
    attr_reader :label, :label_max, :label_min, :range, :id, :order, :display

    def initialize (label, label_max, label_min, range, id,order,display)
        @label = label
        @label_max = label_max
        @label_min = label_min
        @range = range
        @id = id
        @order = order
        @display = display
    end #end initialize

    def edit (label, label_max, label_min, range, order, display)
        @label = label
        @label_max = label_max
        @label_min = label_min
        @range = range
        @order = order
        @display = display
    end #end initialize

    def to_array
        return [@label, @label_max, @label_min, @range, @id, @order,@display]
    end

    def disable
        @hidden = true
    end #end disable

    def enable
        @hidden = false
    end #end disable
    
    def check_label
        return @display? "checked":""
    end #end check_label
    
end

#########################################
# class DateEval
#########################################

class DateEval
    @axes #axes[id][rank]
    @date_string = ""
    @dbase
    @average #average[id]
    @total #total[id]
    GRAPH_PIXEL_LENGTH = 300

    attr_reader :axes, :average, :total

    # constructor
    def initialize (date_string, dbase)
        @dbase = dbase
        @date_string = date_string
        db = PStore.new(@dbase)
        db.transaction do
            #begin transaction
            if db.root?(date_string)
                #read
                @axes = db[date_string]
            else
                #initialize
                @axes = Hash.new
            end
        end

        #end transaction

    end #end constructor

    def get_value(id, rank)
        if @axes.key?(id) && @axes[id][rank] != nil
            return @axes[id][rank]
        else
            return 0
        end
    end

    def get_average(id)
        sum = 0
        vote = 0
        unless @axes.key?(id)
            return 0
        end
        for index in 0..@axes[id].length - 1
            if @axes.key?(id) && @axes[id][index] != nil
                vote += @axes[id][index]
                sum += @axes[id][index] * index
            end
        end
        if @axes[id].length == 0
            return 0
        else
            return sum.to_f/vote + 1
        end
    end

    def vote(id, rank)
        unless @axes.key?(id)
            @axes[id] = Array.new        
        end
        if @axes[id][rank] != nil
            @axes[id][rank] += 1
        else
            @axes[id][rank] = 1
        end
    end

    def save_to_db
        db = PStore.new(@dbase)
        db.transaction do
            #begin transaction
            #save
            db[@date_string] = @axes
        end
        #end transaction
    end #end save_to_db

    def get_graph_length (id, rank)
        unless @axes.key?(id)
            return 0
        end
        if @axes[id][rank] != nil
            total = 0
            @axes[id].each {|val|
                unless val == nil
                    total += val
                end
            }
            return (@axes[id][rank] * GRAPH_PIXEL_LENGTH / total).to_i
        else
            return 0
        end
    end #end

end # class dateEval end

#########################################
# Comment (vote)
#########################################

if (@mode == 'comment')

    if @cgi.params["body"][0] != 'rating'
        return
    end
    @dbase = "#{@cache_path}/rating.db"
    #initialize RatingConfig object
    rating_config = RatingConfig.new(@dbase)
    #initialize DateEval object
    todays_eval = DateEval.new(@cgi.params['date'][0], @dbase)

    rating_config.each { |axis_config|
        if @cgi.params["axis" + axis_config.id.to_s][0]!= nil
            todays_eval.vote(axis_config.id, @cgi.params["axis" + axis_config.id.to_s][0].to_i)
        end
    }
    todays_eval.save_to_db
end
