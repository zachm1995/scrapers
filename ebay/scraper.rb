# Imports
require 'csv'
require 'selenium-webdriver'
require 'awesome_print'
require 'byebug'
require 'warning'

# Supress Warnings
Gem.path.each do |path|
  Warning.ignore(//, path)
end


=begin

This program scrapes completed Ebay listings based on a user provided search query.
It calculates the ratio of sold to unsold items and other useful information.

=end

searchQuery = ""

# Get User input
while (searchQuery.length < 1)
  puts "What are you searching for?"
  searchQuery = gets.chomp.gsub!(/\s/,'+')
end

# Selenium init
driver = Selenium::WebDriver.for :firefox

# Get initial page
driver.get("https://www.ebay.com/sch/i.html?_from=R40&_nkw=#{searchQuery}&_sop=10&LH_Complete=1")

# Set variables
DATE_LIMIT = Date.today - 30
LISTING_LIMIT = driver.find_element(class: 'srp-controls__count-heading').find_element(tag_name: 'span').text.delete(',').to_i
dateIterator = Date.today
listingIterator = 0
pageIterator = 1

if LISTING_LIMIT < 1
  puts "No listings"
  exit(false)
end

settingsObject = {
  dateLimit: DATE_LIMIT,
  listingLimit: LISTING_LIMIT,
  dateIterator: dateIterator,
  listingIterator: listingIterator,
  pageIterator: pageIterator
}

ap settingsObject

# Setup listing arrays
unsoldListings = []
soldListings = []

# Get all listings in the last thirty days
while (dateIterator > DATE_LIMIT && listingIterator < LISTING_LIMIT)
  puts "Processing Page #{pageIterator}\n"
  20.times { print "*"}
  puts ""

  # Get the page
  driver.get("https://www.ebay.com/sch/i.html?_from=R40&_nkw=#{searchQuery}&_sop=10&LH_Complete=1&_pgn=#{pageIterator.to_s}")

  # Get listings on page
  pageListings = driver.find_element(class: "srp-results").find_elements(class: "s-item", tag_name: 'li')

  pageListings.each do |listing|
    # Check if we have reach listing limit
    if listingIterator == LISTING_LIMIT || dateIterator == DATE_LIMIT
      break
    end

    # Listing attributes
    listingPrice = listing.find_element(class: "s-item__price").text.gsub!(/\$/, '').to_f
    listingShippingCost = listing.find_element(class: "s-item__shipping").text[2, listing.find_element(class: "s-item__shipping").text.length - 11].to_f
    listingDate = Date.parse(listing.find_element(class: "s-item__title--tagblock__COMPLETED").text[5, listing.find_element(class: "s-item__title--tagblock__COMPLETED").text.length])
    listingSold = listingSold = listing.find_element(class: "s-item__title--tagblock__COMPLETED").find_elements(class: "NEGATIVE").empty?

    listingObject = {
      price: listingPrice,
      shipping: listingShippingCost,
      date: listingDate,
    }

    # Check if listing sold
    if (listingSold)
      soldListings << listingObject
    else
      unsoldListings << listingObject
    end

    listingIterator += 1
    dateIterator = listingDate
    ap listingObject
  end

  # Go to next page
  pageIterator += 1

end

# Total number of listings
totalListingsCount = listingIterator

# Ratio of sold to unsold
soldRatio = (soldListings.count.to_f / totalListingsCount) * 100

# Average sold price with shipping
avgSoldPrice = soldListings.reduce(0) { |sum, listing| sum + listing[:price] + listing[:shipping] } / soldListings.count
# Average unsold price with shipping
avgUnsoldPrice = unsoldListings.reduce(0) { |sum, listing| sum + listing[:price] + listing[:shipping] } / unsoldListings.count

# Sold ratio of free shipping
soldFreeShippingRatio = soldListings.select { |listing| listing[:shipping] == 0.to_f}.count.to_f / soldListings.count * 100
# Unsold ratio of free shipping
unsoldFreeShippingRatio = unsoldListings.select { |listing| listing[:shipping] == 0.to_f}.count.to_f / unsoldListings.count * 100

# Max price of sold items
maxSoldPrice = soldListings.max_by { |listing| listing[:price] }[:price]

resultObject = {
  totalListings: totalListingsCount,
  percentSold: soldRatio,
  averageSoldPrice: avgSoldPrice,
  soldFreeShippingRatio: soldFreeShippingRatio,
  averageUnsoldPrice: avgUnsoldPrice,
  unsoldFreeShippingRatio: unsoldFreeShippingRatio,
  maxSoldPrice: maxSoldPrice
}

ap "#{searchQuery} had #{totalListingsCount} listings in the past 30 days."
ap "#{soldRatio.round(2)}% of listings sold with an average price of $#{avgSoldPrice.round(2)} and a max price of $#{maxSoldPrice.round(2)}"
ap ""

ap resultObject

ap "Goodbye"