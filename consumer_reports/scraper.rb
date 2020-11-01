require 'selenium-webdriver'
require 'awesome_print'
require 'csv'

username = ENV["CRUSER"]
password = ENV["PASS"]

driver = Selenium::WebDriver.for :firefox

# Authenticate
driver.get('https://secure.consumerreports.org/ec/login')
driver.find_element(id: 'username').send_keys(username)
driver.find_element(id: 'password').send_keys(password)
driver.find_element(xpath: '//button[@type="submit"]').click
driver.get('https://www.consumerreports.org/cars/types/new/suvs/ratings')

i = 900
while (i > 0)
  driver.execute_script('window.scrollTo(0, document.body.scrollHeight);')
  i -= 1
end

elements = driver.find_elements(class: 'table-overall-score-column')

parents = []

elements.each do |this|
  parents << this.find_element(xpath: './..')
end

cars = []
parents.each do |this|
  puts "Processing " + "#{parents.index(this)}"
  puts "Processing " + "#{this.find_element(class: 'model').text}"
  @brand = this.find_element(class: 'cars-preview__info__link_title').text.split[1].gsub(this.find_element(class: 'model').text ,'')
  @model = this.find_element(class: 'model').text
  @lowPrice = this.find_element(class: 'price-range').text.split(' ')[0].tr('^0-9', '') if !this.find_element(class: 'price-range').text.split(' ')[0].nil?
  @highPrice = this.find_element(class: 'price-range').text.split(' ')[2].tr('^0-9', '') if !this.find_element(class: 'price-range').text.split(' ')[2].nil?
  @score = this.find_element(class: 'crux-numbers').text
  @link = this.find_element(class: 'cars-preview__info__link_title').attribute('href')

  car = {
    index: parents.index(this),
    link: @link,
    brand: @brand,
    model: @model,
    lowPrice: @lowPrice,
    highPrice: @highPrice,
    score: @score
  }

  cars << car
end

new_cars = []

cars.each do |car|
  puts "Processing " + "#{cars.index(car)} #{car[:brand]} #{car[:model]}"
  driver.get(car[:link])
  a = []
  driver.find_elements(class: 'bar-ratings-chart-member__score').each do |this|
    a << this
  end

  @road_test = a[0].text.strip if !a[0].nil?
  @reliability = a[1].text.strip if !a[1].nil?
  @satisfaction = a[2].text.strip if !a[2].nil?

  new_cars << car.merge({road_test: @road_test, reliability: @reliability, satisfaction: @satisfaction})

end

CSV.open('cars.csv', 'w') do |csv|
  csv << ["ID", "Brand", "Model", "Low End", "High End", "Score", "Road Test", "Reliability", "Satisfaction"]
  new_cars.each do |car|
    csv << [car[:index], car[:brand], car[:model], car[:lowPrice], car[:highPrice], car[:score], car[:road_test], car[:reliability], car[:satisfaction]]
  end
end