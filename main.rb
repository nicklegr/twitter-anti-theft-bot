#!ruby -Ku

require 'pp'
require 'twitter'

pp Twitter.search("ツンデレってこういう事 -RT", :lang => "ja", :locale => "ja", :rpp => 100, :page => 1) # , 
