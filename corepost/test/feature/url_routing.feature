Using step definitions from: '../steps'

@url_routing
Feature: URL routing
	CorePost should be able to
	correctly route requests
	depending on how the Resource instances
	were registered
	
	@single @single_get
	Scenario: Single resource - GET
		Given 'home_resource' is running
		When as user 'None:None' I GET 'http://127.0.0.1:8080'
		Then I expect HTTP code 200
		And I expect content contains '{}'
		When as user 'None:None' I GET 'http://127.0.0.1:8080/?test=value'
		Then I expect HTTP code 200
		And I expect content contains '{'test': 'value'}'
		When as user 'None:None' I GET 'http://127.0.0.1:8080/test?query=test'
		Then I expect HTTP code 200
		And I expect content contains '{'query': 'test'}'
		When as user 'None:None' I GET 'http://127.0.0.1:8080/test/23/resource/someid'
		Then I expect HTTP code 200
		And I expect content contains '23 - someid'
		
	@single @single_post
	Scenario: Single resource - POST
		Given 'home_resource' is running
		When as user 'None:None' I POST 'http://127.0.0.1:8080/post' with 'test=value&test2=value2'
		Then I expect HTTP code 201
		And I expect content contains '{'test': 'value', 'test2': 'value2'}'		
		
	@single @single_put
	Scenario: Single resource - PUT
		Given 'home_resource' is running
		When as user 'None:None' I PUT 'http://127.0.0.1:8080/put' with 'test=value&test2=value2'
		Then I expect HTTP code 200
		And I expect content contains '{'test': 'value', 'test2': 'value2'}'				
		
	@single @single_delete
	Scenario: Single resource - DELETE
		Given 'home_resource' is running
		When as user 'None:None' I DELETE 'http://127.0.0.1:8080/delete'
		Then I expect HTTP code 200				

	@single @single_post @single_put
	Scenario: Single resource - multiple methods at same URL
		Given 'home_resource' is running
		When as user 'None:None' I POST 'http://127.0.0.1:8080/postput' with 'test=value&test2=value2'
		# POST return 201 by default
		Then I expect HTTP code 201
		And I expect content contains '{'test': 'value', 'test2': 'value2'}'		
		When as user 'None:None' I PUT 'http://127.0.0.1:8080/postput' with 'test=value&test3=value3'
		# PUT return 200 by default
		Then I expect HTTP code 200
		And I expect content contains '{'test': 'value', 'test3': 'value3'}'

	@multi
	Scenario Outline: Multiple resources with submodules
		Given 'multi_resource' is running
		When as user 'None:None' I GET '<url>'
		Then I expect HTTP code 200
		
		Examples:
			| url									|
			| http://127.0.0.1:8081					|
			| http://127.0.0.1:8081/				|
			| http://127.0.0.1:8081/module1			|
			| http://127.0.0.1:8081/module1/		|	
			| http://127.0.0.1:8081/module1/sub		|
			| http://127.0.0.1:8081/module2			|
			| http://127.0.0.1:8081/module2/		|	
			| http://127.0.0.1:8081/module2/sub		|

	@501
	Scenario: Existing URLs with wrong HTTP method returns 501 error
		Given 'home_resource' is running
		When as user 'None:None' I DELETE 'http://127.0.0.1:8080/postput'
		Then I expect HTTP code 501
		When as user 'None:None' I GET 'http://127.0.0.1:8080/postput'
		Then I expect HTTP code 501

    @head
    Scenario: Support for HTTP HEAD
        Given 'home_resource' is running
        When as user 'None:None' I GET 'http://127.0.0.1:8080/methods/head'
        Then I expect HTTP code 501
		When as user 'None:None' I HEAD 'http://127.0.0.1:8080/methods/head'
		Then I expect HTTP code 200

    @options
    Scenario: Support for HTTP OPTIONS
        Given 'home_resource' is running
        When as user 'None:None' I GET 'http://127.0.0.1:8080/methods/options'
        Then I expect HTTP code 501
		When as user 'None:None' I OPTIONS 'http://127.0.0.1:8080/methods/options'
		#this is unexpected - need to verify with kaosat
		Then I expect HTTP code 501

    @patch
    Scenario: Support for HTTP PATCH
        Given 'home_resource' is running
        When as user 'None:None' I GET 'http://127.0.0.1:8080/methods/options'
        Then I expect HTTP code 501
        #this is unexpected - need to verify with kaosat
		When as user 'None:None' I PATCH 'http://127.0.0.1:8080/methods/patch' with 'tes1=value1&test2=value2'
		Then I expect HTTP code 501


