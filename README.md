Twisted REST micro-framework
================================

Based on *Flask* API, with plans for integrated multiprocessing support for full usage of all CPUs. 
Provides a more Flask/Sinatra-style API on top of the core *twisted.web* APIs.

Geared towards creating REST-oriented server platforms.
Tested on PyPy (recommended) and Python 2.7 for maximum performance.

Single REST module example
--------------------------

The simplest possible REST application:

    from corepost.web import route, RESTResource
    from corepost.enums import Http
    
    class RESTService():
    
        @route("/",Http.GET)
        def root(self,request,**kwargs):
            return request.path
        
        @route("/test",Http.GET)
        def test(self,request,**kwargs):
            return request.path
        
        @route("/test/<int:numericid>",Http.GET)
        def test_get_resources(self,request,numericid,**kwargs):
            return "%s" % numericid
    
    if __name__ == '__main__':
        app = RESTResource((RESTService,))
        app.run()


Multi-module REST application
--------------------------------

Once can assemble a multi-module REST applications with
different REST services responding from different context paths.
Notice the class *path* attribute which provides a common URL prefix for all REST operations
on a particular service:

	from corepost import Response, NotFoundException, AlreadyExistsException
	from corepost.web import RESTResource, route, Http 

	class CustomerRESTService():
	    path = "/customer"
	
	    @route("/")
	    def getAll(self,request):
	        return DB.getAllCustomers()
	    
	    @route("/<customerId>")
	    def get(self,request,customerId):
	        return DB.getCustomer(customerId)
	    
	    @route("/",Http.POST)
	    def post(self,request,customerId,firstName,lastName):
	        customer = Customer(customerId, firstName, lastName)
	        DB.saveCustomer(customer)
	        return Response(201)
	    
	    @route("/<customerId>",Http.PUT)        
	    def put(self,request,customerId,firstName,lastName):
	        c = DB.getCustomer(customerId)
	        (c.firstName,c.lastName) = (firstName,lastName)
	        return Response(200)
	
	    @route("/<customerId>",Http.DELETE)
	    def delete(self,request,customerId):
	        DB.deleteCustomer(customerId)
	        return Response(200)
	    
	    @route("/",Http.DELETE)
	    def deleteAll(self,request):
	        DB.deleteAllCustomers()
	        return Response(200)
	
	class CustomerAddressRESTService():
	    path = "/customer/<customerId>/address"
	
	    @route("/")
	    def getAll(self,request,customerId):
	        return DB.getCustomer(customerId).addresses
	    
	    @route("/<addressId>")
	    def get(self,request,customerId,addressId):
	        return DB.getCustomerAddress(customerId, addressId)
	    
	    @route("/",Http.POST)
	    def post(self,request,customerId,addressId,streetNumber,streetName,stateCode,countryCode):
	        c = DB.getCustomer(customerId)
	        address = CustomerAddress(streetNumber,streetName,stateCode,countryCode)
	        c.addresses[addressId] = address
	        return Response(201)
	    
	    @route("/<addressId>",Http.PUT)        
	    def put(self,request,customerId,addressId,streetNumber,streetName,stateCode,countryCode):
	        address = DB.getCustomerAddress(customerId, addressId)
	        (address.streetNumber,address.streetName,address.stateCode,address.countryCode) = (streetNumber,streetName,stateCode,countryCode)
	        return Response(200)
	
	    @route("/<addressId>",Http.DELETE)
	    def delete(self,request,customerId,addressId):
	        DB.getCustomerAddress(customerId, addressId) #validate address exists
	        del(DB.getCustomer(customerId).addresses[addressId])
	        return Response(200)
	    
	    @route("/",Http.DELETE)
	    def deleteAll(self,request,customerId):
	        c = DB.getCustomer(customerId)
	        c.addresses = {}
	        return Response(200)
	
	
	def run_rest_app():
	    app = RESTResource((CustomerRESTService(),CustomerAddressRESTService()))
	    app.run(8080)
	    
	if __name__ == "__main__":
	    run_rest_app()

The example above creates 2 REST services and exposes the following resources:

	http://127.0.0.1:8080/customer
	http://127.0.0.1:8080/customer/<customerId>					
	http://127.0.0.1:8080/customer/<customerId>/address
	http://127.0.0.1:8080/customer/<customerId>/address/>addressId>

Path argument extraction
------------------------

CorePort can easily extract path arguments from an URL and convert them to the desired type.

The supported types are:

* *int*
* *float*
* *string*

Example:

	@route("/int/<int:intarg>/float/<float:floatarg>/string/<stringarg>",Http.GET)
	def test(self,request,intarg,floatarg,stringarg,**kwargs):
		pass

@defer.inlineCallbacks support
------------------------------

If you want a deferred async method, just use *defer.returnValue()*

	@route("/",Http.GET)
	@defer.inlineCallbacks
	def root(self,request,**kwargs):
		val1 = yield db.query("SELECT ....")
		val2 = yield db.query("SELECT ....")
		defer.returnValue(val1 + val2)
	    
Argument validation
-------------------

CorePost integrates the popular 'formencode' package to implement form and query argument validation.
Validators can be specified using a *formencode* Schema object, or via custom field-specific validators, e.g.:

	from corepost.web import validate, route
	from corepost.enums import Http
	from formencode import Schema, validators

	class TestSchema(Schema):
	    allow_extra_fields = True
	    childId = validators.Regex(regex="^value1|value2$")
	
	class MyApp():
		
		@route("/validate/<int:rootId>/schema",Http.POST)
		@validate(schema=TestSchema())
		def postValidateSchema(self,request,rootId,childId,**kwargs):
		    '''Validate using a common schema'''
		    return "%s - %s - %s" % (rootId,childId,kwargs)
		
		@route("/validate/<int:rootId>/custom",Http.POST)
		@validate(childId=validators.Regex(regex="^value1|value2$"))
		def postValidateCustom(self,request,rootId,childId,**kwargs):
		    '''Validate using argument-specific validators'
		    return "%s - %s - %s" % (rootId,childId,kwargs)	    

Please see the *FormEncode* <http://www.formencode.org/en/latest/Validator.html> documentation
for list of available validators:

* Common <http://www.formencode.org/en/latest/modules/validators.html#module-formencode.validators>
* National <http://www.formencode.org/en/latest/modules/national.html#module-formencode.national>

Content types
-------------

CorePost integrates support for JSON, YAML and XML (partially) based on request content types.

*Parsing of incoming content*

Based on the incoming content type in POST/PUT requests,
the body will be automatically parsed to JSON, YAML and XML (ElementTree)

* request.json
* request.yaml
* request.xml

 and attached to the request:

	@route("/post/json",(Http.POST,Http.PUT))
	def test_json(self,request,**kwargs):
	    return "%s" % json.dumps(request.json)
	
	@route("/post/xml",(Http.POST,Http.PUT))
	def test_xml(self,request,**kwargs):
	    return "%s" % ElementTree.tostring(request.xml)
	
	@route("/post/yaml",(Http.POST,Http.PUT))
	def test_yaml(self,request,**kwargs):
	    return "%s" % yaml.dump(request.yaml)


*Routing requests by incoming content type*

Based on the incoming content type in POST/PUT requests, the *same* URL can be hooked up to different router methods:

    @route("/post/by/content",(Http.POST,Http.PUT),MediaType.APPLICATION_JSON)
    def test_content_app_json(self,request,**kwargs):
        return request.received_headers[HttpHeader.CONTENT_TYPE]

    @route("/post/by/content",(Http.POST,Http.PUT),(MediaType.TEXT_XML,MediaType.APPLICATION_XML))
    def test_content_xml(self,request,**kwargs):
        return request.received_headers[HttpHeader.CONTENT_TYPE]

    @route("/post/by/content",(Http.POST,Http.PUT),MediaType.TEXT_YAML)
    def test_content_yaml(self,request,**kwargs):
        return request.received_headers[HttpHeader.CONTENT_TYPE]

    @route("/post/by/content",(Http.POST,Http.PUT))
    def test_content_catch_all(self,request,**kwargs):
        return MediaType.WILDCARD

*Converting Python objects to content type based on what caller can accept*

Instead of returning string responses, the code can just return Python objects.
Depending whether the caller can accept JSON (default) or YAML, the Python objects will be automatically converted:

    @route("/return/by/accept")
    def test_return_content_by_accepts(self,request,**kwargs):
        val = [{"test1":"Test1"},{"test2":"Test2"}]
        return val
        
Calling this URL with "Accept: application/json" will return:

	[{"test1": "Test1"}, {"test2": "Test2"}]
	
Calling it with "Accept: text/yaml" will return:

	- {test1: Test1}
	- {test2: Test2} 


HTTP codes
------------------

Success:

* 200 (OK) - GET, DELETE, PUT
* 201 (Created) - POST
	
Errors:

* 404 - not able to match any URL
* 400 - missing mandatory argument (driven from the arguments on the actual functions)
* 400 - argument failed validation
* 500 - server error
	   
Filters
-----------------

There is support for CorePost resource filters via the two following *corepost.filter* interfaces:

	class IRequestFilter(Interface):
	    """Request filter interface"""    
	    def filterRequest(self,request):
	        """Allows to intercept and change an incoming request"""
	        pass
	
	class IResponseFilter(Interface):
	    """Response filter interface"""
	    def filterResponse(self,request,response):
	        """Allows to intercept and change an outgoing response"""
	        pass

A filter class can implement either of them or both (for a wrap around filter), e.g.:

	class AddCustomHeaderFilter():
	    """Implements a request filter that adds a custom header to the incoming request"""
	    zope.interface.implements(IRequestFilter)
	    
	    def filterRequest(self,request):
	        request.received_headers["Custom-Header"] = "Custom Header Value"
	
	class Change404to503Filter():
	    """Implements just a response filter that changes 404 to 503 statuses"""
	    zope.interface.implements(IResponseFilter)
	    
	    def filterResponse(self,request,response):
	        if response.code == 404:
	            response.code = 503

	class WrapAroundFilter():
	    """Implements both types of filters in one class"""
	    zope.interface.implements(IRequestFilter,IResponseFilter)
	
	    def filterRequest(self,request):
	        request.received_headers["X-Wrap-Input"] = "Input"
	    
	    def filterResponse(self,request,response):
	        response.headers["X-Wrap-Output"] = "Output"


In order to activate the filters on a RESTResource instance, you need to pass a list of them in the constructor as the *filters* parameter, e.g.:
 	   
 	   
	class FilterApp():
	    
	    @route("/",Http.GET)
	    def root(self,request,**kwargs):
	        return request.received_headers
	
	def run_filter_app():
	    app = RESTResource(services=((FilterApp(),),filters=(Change404to503Filter(),AddCustomHeaderFilter(),WrapAroundFilter(),))
	    app.run(8083)

	    	        
Performance
-----------

On par with raw *twisted.web* performance. Minimal overhead for URL routing and function argument extraction.

BDD unit tests
--------------

All unit tests for CorePost are in BDD feature format, using Freshen.
Can be run using:

	nosetests --with-freshen -v

Plans
-----

* integrate multi core support
