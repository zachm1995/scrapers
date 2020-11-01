require 'csv'
require 'selenium-webdriver'
require 'awesome_print'
require 'byebug'


driver = Selenium::WebDriver.for :firefox

driver.get('https://www.cargurus.com/')
driver.find_element(class: 'ft-homepage-search__tabs__new-car').click

makes = []

driver.find_elements(xpath: '//select[@id="carPickerNew_makerSelect"]/optgroup[@label="All Makes"]/option').each do |this|
  makes << {name: this.attribute('text'), id: this.attribute('value')}
end

option = Selenium::WebDriver::Support::Select.new(driver.find_element(id: 'carPickerNew_makerSelect'))

cars = []
makes.each do |this|
  puts "Processing #{this[:name]} (#{makes.index(this) + 1}/#{makes.size})"

  option = Selenium::WebDriver::Support::Select.new(driver.find_element(id: 'carPickerNew_makerSelect'))
  option.select_by(:text, this[:name])
  driver.find_elements(xpath: '//select[@id="carPickerNew_modelSelect"]/option[@class="selectOption"]').each do |that|
    cars << {make: this[:name], make_id: this[:id], model: that.text, model_id: that.attribute('value')}
  end
end

puts "Select a make by number"

makes.each do |this|
  puts "#{makes.index(this)}. #{this[:name]}"
end
selected_make = makes[gets.chomp.to_i]

selected_make_models = cars.select { |car| car[:make] == selected_make[:name]}
puts "Select a model"
selected_make_models.each do |this|
  puts "#{selected_make_models.index(this)}. #{this[:model]}"
end
selected_model = selected_make_models[gets.chomp.to_i]

puts "What's your zipcode?"
zipcode = gets.chomp

driver.get("https://www.cargurus.com/Cars/new/searchresults.action?sourceContext=homePageNewCarTab_true_0&selectedEntity=#{selected_model[:model_id]}&zip=#{zipcode}&distance=50")

results_per_page = driver.find_elements(xpath: '//span[@class="_3gQBBs"]/strong')[0].text.split().last.to_f
total_results = driver.find_elements(xpath: '//span[@class="_3gQBBs"]/strong')[1].text.split().last.to_f
total_pages = (total_results/results_per_page).ceil
current_page = 1
prices = []

(1..total_pages).each do |page|
  url = "https://www.cargurus.com/Cars/new/searchresults.action?sourceContext=homePageNewCarTab_true_0&selectedEntity=#{selected_model[:model_id]}&zip=#{zipcode}&distance=50#resultsPage=#{page}"
  puts "Processing page #{page}"
  driver.get(url)
  driver.find_elements(xpath: '//div[@class="_498r1y"]').each do |this|
    puts "1"
    begin
      ap prices << this.text.gsub(this.find_element(class: '_2vJNJ1').text, '').chomp.tr('^0-9', '')
      puts "2"
    rescue
      puts "3"
      ap prices << this.text.chomp.tr('^0-9', '')
      next
    end
  end
  puts  "#{prices.size} prices saved"
end

byebug

ap prices

puts this.find_element(class: '_2vJNJ1').exists?

a=driver.find_elements(xpath: '//div[@class="_498r1y"]')