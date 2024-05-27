#!/usr/bin/env python


from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
import random
import string
import os

# Set the path to the directory containing geckoDriver
firefox_driver_path = '/usr/bin/geckodriver'
firefox_executable = '/usr/bin/firefox'
os.environ['PATH'] += os.pathsep + firefox_driver_path
firefox_options = Options()
firefox_options.add_argument("--headless")
firefox_options.add_argument("--no-sandbox")
firefox_options.binary_location = firefox_executable
driver = webdriver.Firefox(options=firefox_options)

url = os.getenv('url')
username = os.getenv('username')
password = os.getenv('password')

driver = webdriver.Firefox()
driver.get(url)
title = driver.title
assert title in driver.title
time.sleep(random.randint(0, 5))

try:
  elem = driver.find_element(By.XPATH, "//*[contains(text(), 'Use phone / email / username')]")
  driver.execute_script("arguments[0].click();", elem)
  time.sleep(random.randint(0, 5))
except NoSuchElementException:
  elem = driver.find_element(By.ID, "header-login-button")
  driver.execute_script("arguments[0].click();", elem)
  time.sleep(random.randint(0, 5))
  elem = driver.find_element(By.XPATH, "//*[contains(text(), 'Use phone / email / username')]")
  driver.execute_script("arguments[0].click();", elem)
  time.sleep(random.randint(0, 5))

elem = driver.find_element(By.XPATH, "//*[contains(text(), 'Log in with email or username')]")
driver.execute_script("arguments[0].click();", elem)
time.sleep(random.randint(0, 5))
elem = driver.find_element(By.CLASS_NAME, "css-11to27l-InputContainer.etcs7ny1")
elem.send_keys(username)
time.sleep(random.randint(0, 5))
elem = driver.find_element(By.CLASS_NAME, "css-wv3bkt-InputContainer.etcs7ny1")
elem.send_keys(password)
time.sleep(random.randint(0, 5))
elem = driver.find_element(By.CLASS_NAME, "e1w6iovg0.css-11sviba-Button-StyledButton.ehk74z00")
driver.execute_script("arguments[0].click();", elem)
time.sleep(random.randint(0, 5))
slider = driver.find_element(By.CLASS_NAME, "secsdk-captcha-drag-icon.sc-hMqMXs.VZMN")

# Perform sliding action
for x in range(10000):
    
    actions.move_to_element(slider).click_and_hold().move_by_offset(x, 0).release().perform()
    time.sleep(0.1)
