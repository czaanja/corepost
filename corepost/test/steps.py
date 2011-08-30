'''
Common Freshen BDD steps

@author: jacekf
'''
from multiprocessing import Process
import httplib2, json, re, time
from freshen import Before, After, Given, When, Then, scc, assert_equals, assert_true #@UnresolvedImport
from urllib import urlencode
from corepost.test.home_resource import run_app_home

apps = {'home_resource' : run_app_home}

def as_dict(parameters):
    dict_val = {}
    for pair in parameters.split('&') : 
        params = pair.split('=', 1)
        if (params[0] != None) and (len(params) == 2):
            dict_val[params[0]] = params[1]
    return dict_val

##################################
# BEFORE / AFTER
##################################

@Before
def setup(slc):
    scc.processes = []
    scc.http_headers = {}

@After
def cleanup(slc):
    # shut down processes
    for process in scc.processes:
        process.terminate()

##################################
# GIVEN
##################################

@Given(r"^'(.+)' is running\s*$")
def given_process_is_running(processname):
    process = Process(target=apps[processname])
    process.daemon = True
    process.start()
    scc.processes.append(process)
    time.sleep(0.25) # let it start up

##################################
# WHEN
##################################

@When(r"^as user '(.+):(.+)' I (GET|DELETE) '(.+)'\s*$")
def when_as_user_i_send_get_delete_to_url(user,password,method,url):
    h = httplib2.Http()
    h.follow_redirects = False
    h.add_credentials(user, password)
    scc.response, scc.content = h.request(url, method)

@When(r"^as user '(.+):(.+)' I (POST|PUT) '(.+)' with '(.+)'\s*$")
def when_as_user_i_send_post_put_to_url(user,password,method,url,params):
    h = httplib2.Http()
    h.follow_redirects = False
    h.add_credentials(user, password)
    scc.http_headers['Content-type'] = 'application/x-www-form-urlencoded'
    scc.response, scc.content = h.request(url, method, urlencode(as_dict(params)), headers = scc.http_headers)

@When(r"^as user '(.+):(.+)' I (POST|PUT) '(.+)' with (XML|JSON)\s*$")
def when_as_user_i_send_post_put_xml_json_to_url(payload,user,password,method,url,request_type):
    h = httplib2.Http()
    h.follow_redirects = False
    h.add_credentials(user, password)
    scc.http_headers['Content-type'] = 'application/json' if request_type == "JSON" else 'text/xml'
    scc.response, scc.content = h.request(url, method, payload, headers = scc.http_headers)

##################################
# THEN
##################################

@Then(r"^I expect HTTP code (\d+)\s*$")
def expect_http_code(code):
    assert_equals(int(code),int(scc.response.status), msg="%s != %s\n%s\n%s" % (code,scc.response.status,scc.response,scc.content))

@Then(r"^I expect content contains '(.+)'\s*$")
def expect_content(content):
    assert_true(scc.content.find(content) >= 0,"Did not find:\n%s\nin content:\n%s" % (content,scc.content)) 

@Then(r"^I expect content contains\s*$")
def expect_content_multiline(content):
    assert_true(scc.content.find(content) >= 0,"Did not find:\n%s\nin content:\n%s" % (content,scc.content)) 

@Then(r"^I expect '([^']*)' header matches '([^']*)'\s*$")
def then_check_http_header_matches(header,regex):
    assert_true(re.search(regex,scc.response[header.lower()], re.X | re.I) != None, 
                "the regex %s does not match the response\n%s" % (regex, scc.response[header.lower()])) 


