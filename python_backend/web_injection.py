#Use selenium to inject into Walmart or some other grocery ordering service!
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from time import sleep

def buy_items(items_quants):
    driver = webdriver.Chrome("/Users/clareheinbaugh/Desktop/ramhacks/chromedriver")

    driver.get('https://giantfood.com/')

    #Stuff for signing in - doesn't work
    # driver.find_element_by_xpath("//button[@class='button button--prime button-width--full']").click()
    #
    # sleep(2)
    # enter_email = driver.find_element_by_xpath("//input[@id='username']")
    # enter_email.clear()
    # enter_email.send_keys(email)
    #
    # enter_password = driver.find_element_by_xpath("//input[@type='password']")
    # enter_password.clear()
    # enter_password.send_keys(password)
    #
    # sleep(2)
    # driver.find_element_by_xpath("//button[@type='submit']").click()

    #Close initial popups
    driver.find_element_by_xpath("//button[@class='button button--light-grey button-width--flex header-content_button']").click()
    sleep(2) #TODO: better solution
    driver.find_element_by_xpath("//button[@aria-label='close dialog']").click()

    #Search for an item
    for item in items_quants.keys():
        elem = driver.find_element_by_id('typeahead-search-input')
        elem.clear()
        elem.send_keys(item)
        elem.send_keys(Keys.RETURN)

        #Add the item to cart
        sleep(3)
        driver.find_element_by_xpath("//li[@id='product-0']//button[@aria-label='Add to Cart']").click()
        sleep(5)

        ct = items_quants[item] - 1
        while ct > 0:
            #add another to the cart...
            driver.find_element_by_xpath("//button[@aria-label='Add One More To Cart']").click()
            sleep(3)
            ct -= 1
        sleep(3)

    #Go to checkout
    driver.find_element_by_xpath("//button[@class='btn btn--primary cart-btn global-header_cart-button-container btn--small']").click()
    sleep(5)

    # driver.close()

if __name__ == '__main__':
    buy_items({'milk' : 3, 'eggs' : 2, 'sugar' : 1})
    # buy_items({'milk' : 3})
