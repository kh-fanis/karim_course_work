# encoding: utf-8
Shoes.setup do
  gem "activerecord"
  gem "sqlite3"
  gem "logger"
end

require_relative "app"

Shoes.app :height => 610, :width => 610 do

  #####################################################################################################
  # Settings ##########################################################################################

  @pages, @menu_buttons = {}, {}

  menu_button_titles = [
    { :title => :items,      :russian => "Товары"  },
    { :title => :categories, :russian => "Категории" },
    { :title => :add,        :russian => "Добавить"  }
  ]

  buttons_height = 70

  button_width = 610 / menu_button_titles.size

  pages_height = 610 - buttons_height - 20

  pages_width  = 610

  image_size = 38

  #####################################################################################################
  # Menu ##############################################################################################

  flow :width => "100%" do

    menu_button_titles.each do |hash|

      f = flow :width => button_width do

        button = stack :width => button_width - 1, :height => buttons_height do
          background gray
          para hash[:russian], :align => "center"
          i = image "imgs/#{hash[:title]}.png", :width => image_size, :height => image_size
          i.move ((button_width - image_size) / 2), 25
        end

        @menu_buttons[hash[:title]] = button

      end

    end

  end

  #####################################################################################################
  # Pages #############################################################################################

  #####################################################################################################
  # Items Page ########################################################################################

  s = stack :width => pages_width, :height => pages_height do
  end
  @pages[:items] = s

  #####################################################################################################
  # Categories Page ###################################################################################

  s = stack :width => pages_width, :height => 0, :hidden => true do
  end
  @pages[:categories] = s

  #####################################################################################################
  # Add Page ##########################################################################################

  s = stack :width => pages_width, :height => 0, :hidden => true do
  end
  @pages[:add] = s

  #####################################################################################################
  # Setting CallBacks To Menu Buttons #################################################################

  @menu_buttons.each do |k, b|
    b.click do
      @pages.each { |k, v| v.style(:height => 0); v.hide }
      @pages[k].style(:height => pages_height)
      @pages[k].show
      run_controller(k)
    end
  end

  #####################################################################################################
  # Controllers #######################################################################################

  def run_controller name, attrs = {}
    page = @pages[name]
    page.clear
    page.append do

      case name

      #################################################################################################
      # Items Controller ##############################################################################
      when :items

        search_key = attrs[:search_key].nil? ? "Search key" : attrs[:search_key]
        @categories = Category.all

        flow :margin => 10 do

          @search = {
            :line => edit_line(search_key, :margin_top => 2, :width => 340),
            :category => list_box(:items => ["Категория"] + @categories.map(&:name),
              :width => 150, :margin_top => 2, :margin_left => 10, :choose => "Категория"),
            :button => button("Search", :margin_left => 10, :width => 95) do
              run_controller :items, :search_key => @search[:line].text
            end
          }

        end

        stack width: "100%", height: "100%", :scroll => true do
          Item.all.each do |item|
            flow do
              background gray
              img_url = "imgs/items/#{item.id}.png"
              File.exist?(Dir.pwd + "/" + img_url) ?
                image(img_url, :width => 100) : image("imgs/items.png", :width => 100)
              stack :width => 450 do
                caption "#{item.name} | Цена: #{item.price} rub"
                inscription item.description
              end
              stack :width => 50 do
                button "Edit", :width => "100%", :margin => 3
                button "Удалить", :width => "100%", :margin => 3 do
                  item.destroy if confirm "Вы уверены?"
                  run_controller :items, :search_key => @search[:line].text
                end
              end
            end
            stack :width => "100%", :height => 1 do background white end
          end
        end

      #################################################################################################
      # Categories Controller #########################################################################
      when :categories
        @categories = Category.all
        flow :margin => 10 do

          @search = [
            :line => edit_line("Search key", :margin_top => 2, :width => 490),
            :button => button("Search", :margin_left => 10, :width => 95)
          ]

        end

        stack width: "100%", height: "100%", :scroll => true do
          Category.all.each do |category|
            flow do
              background gray
              stack :width => 380 do
                caption "#{category.name}"
              end
              flow :width => 220 do
                button "Edit", :width => 50, :margin => 3
                button "Удалить", :width => 55, :margin => 3 do
                  if confirm "Вы уверены?"
                    category.items.each do |item| item.destroy end
                    category.destroy
                    run_controller :categories
                  end
                end
                button "Показать товары", :width => 115, :margin => 3 do
                  run_controller :items
                end
              end
            end
            stack :width => "100%", :height => 1 do background white end
          end
        end

      #################################################################################################
      # Addition Controller ###########################################################################
      when :add
        flow :width => "100%", :margin_left => 210 do
          @radio_add_item = radio :checked => true do
            @flow_for_items.show
            @flow_for_categories.hide
          end
          para "Товар"
          @radio_add_category = radio do
            @flow_for_categories.show
            @flow_for_items.hide
          end
          para "Категорию"
        end
        @field_for_errors = stack do
          inscription "Успешно сохранено в БД", :stroke => green, :align => "center" if attrs[:success]
        end
        @flow_for_items = flow :margin_left => 125 do
          @categories = Category.all
          stack :width => 150 do
            [
              para("Наименование"),
              para("Описание"),
              para("Цена", :margin_top => 120),
              para("Категория"),
              para("Штрих Код")
            ]
          end
          stack :width => 200 do
            @data_to_save = {
              :name => edit_line(:height => 32),
              :description => edit_box(:height => 150),
              :price => edit_line(:height => 32),
              :category => list_box(:items => @categories.map(&:name), :height => 40),
              :barcode => edit_line(:height => 32)
            }.each do |k, i| i.style(:margin => 5) end
          end
        end
        @flow_for_categories = flow :margin_left => 125, :hidden => true do
          stack :width => 150 do
            para "Наименование"
          end
          stack :width => 200 do
            @category_name_to_create = edit_line :height => 32, :margin => 5
          end
        end
        button "Добавить", :width => 350, :margin_left => 200 do
          save_object = nil
          if @radio_add_item.checked
            category = Category.find_by name: @data_to_save[:category].text
            save_object = Item.new :name => @data_to_save[:name].text,
              :description => @data_to_save[:description].text,
              :price => @data_to_save[:price].text,
              :category => category,
              :barcode => @data_to_save[:barcode].text
            @field_for_errors.clear
          else
            save_object = Category.create :name => @category_name_to_create.text
          end
          if save_object.save
            run_controller :add, { :success => true }
          else
            save_object.errors.messages.each do |k, v|
              v.each do |m|
                @field_for_errors.append { inscription(m, :align => "center", :stroke => red) }
              end
            end
          end
        end
      end
    end
  end

  run_controller :items

end