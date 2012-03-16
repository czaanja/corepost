Using step definitions from: '../steps'

@arguments
Feature: Arguments
	CorePost should be able to correctly extract arguments
	from paths, query arguments, form arguments and JSON documents
	
	@arguments_ok
	Scenario Outline: Path argument extraction
		Given 'arguments' is running
		When as user 'None:None' I GET 'http://127.0.0.1:8082<url>'
		Then I expect HTTP code <code>
		And I expect content contains '<content>'

		Examples:
			| url												| code	| content																|
			| /int/1/float/1.1/string/TEST						| 200	| [(<type 'int'>, 1), (<type 'float'>, 1.1), (<type 'str'>, 'TEST')]	|
			| /int/1/float/1/string/TEST						| 200	| [(<type 'int'>, 1), (<type 'float'>, 1.0), (<type 'str'>, 'TEST')]	|
			| /int/1/float/1/string/23							| 200	| [(<type 'int'>, 1), (<type 'float'>, 1.0), (<type 'str'>, '23')]	|
						
	@arguments_error
	Scenario Outline: Path argument extraction - error handling
		Given 'arguments' is running
		When as user 'None:None' I GET 'http://127.0.0.1:8082<url>'
		Then I expect HTTP code <code>
		And I expect content contains '<content>'

		Examples:
			| url												| code	| content																|
			| /int/WRONG/float/1.1/string/TEST					| 404	| URL '/int/WRONG/float/1.1/string/TEST' not found						|
			| /int/1/float/WRONG/string/TEST					| 404	| URL '/int/1/float/WRONG/string/TEST' not found						|

	@arguments_by_type
	Scenario Outline: Parse form arguments OR from JSON documents for POST / PUT
		Given 'arguments' is running
		
		# pass in as form arguments
		When as user 'None:None' I <method> 'http://127.0.0.1:8082/formOrJson' with 'first=John&last=Doe'
		Then I expect HTTP code <code>
		And I expect content contains 'John Doe'
		
		# pass in as *** JSON *** document
		When as user 'None:None' I <method> 'http://127.0.0.1:8082/formOrJson' with JSON
		"""
		{"first":"Jane","last":"Doeovskaya"}
		"""
		Then I expect HTTP code <code>
		And I expect content contains 'Jane Doeovskaya'
		# additional arguments should be OK
		When as user 'None:None' I <method> 'http://127.0.0.1:8082/formOrJson' with JSON
		"""
		{"first":"Jane","last":"Doeovskaya","middle":"Oksana"}
		"""
		Then I expect HTTP code <code>
		And I expect content contains 'Jane Doeovskaya'

		# pass in as *** YAML *** document
		When as user 'None:None' I <method> 'http://127.0.0.1:8082/formOrJson' with YAML
		"""
first: Oksana
last: Dolovskaya
		"""
		Then I expect HTTP code <code>
		And I expect content contains 'Oksana Dolovskaya'
		# additional arguments should be OK
		When as user 'None:None' I <method> 'http://127.0.0.1:8082/formOrJson' with YAML
		"""
first: Svetlana
middle: Jane
last: Gingrychnoya
		"""
		Then I expect HTTP code <code>
		And I expect content contains 'Svetlana Gingrychnoya'

		# pass in as *** XML *** document wit both attributes and child nodes
		When as user 'None:None' I <method> 'http://127.0.0.1:8082/formOrJson' with XML
		"""
<root first="John" last="Doe" middle="Jim"/>
		"""
		Then I expect HTTP code <code>
		And I expect content contains 'John Doe'

		When as user 'None:None' I <method> 'http://127.0.0.1:8082/formOrJson' with XML
		"""
<root first="Jan" middle="Jim">
	<last>Dolowski</last>
</root>
		"""
		Then I expect HTTP code <code>
		And I expect content contains 'Jan Dolowski'

		When as user 'None:None' I <method> 'http://127.0.0.1:8082/formOrJson' with XML
		"""
<root>
	<first>Grzegorz</first> 
	<middle>Jim</middle>
	<last>Brzeczyszczykiewicz</last>
</root>
		"""
		Then I expect HTTP code <code>
		And I expect content contains 'Grzegorz Brzeczyszczykiewicz'

		Examples:
			| method	| code	|
			| POST		| 201	|
			| PUT		| 200	|
											