# OAUTH2

[[_TOC_]]

## Roles

- **resource owner**: An entity capable of granting access to a protected resource. When the resource owner is a person, it is referred to as an end-user

- **resource server**: The server hosting the protected resources, capable of accepting and responding to protected resource requests using access tokens.

- **client**: An application making protected resource requests on behalf of the resource owner and with its authorization.  The term "client" does not imply any particular implementation characteristics (e.g., whether the application executes on a server, a desktop, or other devices).

- **authorization server**: The server issuing access tokens to the client after successfully authenticating the resource owner and obtaining authorization.

## Schemes

### Authorization Code Grant

The authorization code grant type is used to obtain both access
tokens and refresh tokens and is optimized for **confidential clients**.
Since this is a redirection-based flow, the **client** must be capable of
interacting with the resource owner's **user-agent** (typically a web
browser) and capable of receiving incoming requests (via redirection)
from the authorization server.

#### Architecture

```

```

#### Runtime view

```plantuml
actor "Resource Owner" as resource_owner
participant "User Agent\n(Tipically a **Web Browser**)" as user_agent
participant "Client" as client
participant "Authorization Server" as authorization_server
participant "Resource Server" as resource_server

user_agent <-- client: A. **Direct** to **Authorization Server**
user_agent -> authorization_server: A. GET URI ?**clientid**=...&\n**redirect_uri**=https://client...&\n**response_type**=**code**&\nscope&state
user_agent <-- authorization_server: A. Render Authorization Page
resource_owner -> user_agent : B. **Resource Owner**\nauthenticates\nand Grants Client 
user_agent -> authorization_server: B. **Resource Owner** Grants **Client** 
user_agent <-- authorization_server: C. **302** to URI **redirect_uri**?**authorization_code**
user_agent -> client: C. Request Access Token with **authorization_code**
client -> authorization_server: D. Request Access Token with:\n**authorization_code**\n**client_id**\n**client_secret**\n**redirect_uri** (step C.)
client <-- authorization_server: E. {**access_token**:...}
```

**A.** The client initiates the flow by directing the resource owner's user-agent to the authorization endpoint.  The client includes: 
  - **client identifier**
  - **requested scope**
  - **local state**
  - **redirection URI** to which the authorization server will send the user-agent back once access is granted (or denied).

For example, the client directs the user-agent to make the following
HTTP request:

```http
GET /authorize?response_type=code&client_id=s6BhdRkqt3&state=xyz&redirect_uri=https%3A%2F%2Fclient%2Eexample%2Ecom%2Fcb HTTP/1.1
Host: server.example.com
````
**B.** The **authorization server** authenticates the **resource owner** (via the user-agent) and establishes whether the resource owner grants or denies the client's access request.


**C.** Assuming the **resource owner** grants access, the **authorization server** redirects the **user-agent** back to the **client** using the **redirection URI** provided earlier *(in the request or during client registration)*.  The redirection URI includes an **authorization code** and any local state provided by the client earlier

For example, the authorization server redirects the user-agent by
sending the following HTTP response:

```http
HTTP/1.1 302 Found
Location: https://client.example.com/cb?code=SplxlOBeZQQYbYS6WxSbIA&state=xyz
```

**D.** The **client** requests an **access token** from the **authorization server**'s token endpoint by including the **authorization code received** in the previous step. When making the request, the **client** *authenticates* with the **authorization server**.  The **client** **includes** the **redirection URI** used to obtain the authorization code for verification

For example, the client makes the following HTTP request using TLS
(with extra line breaks for display purposes only):
```http
POST /token HTTP/1.1
Host: server.example.com
Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=SplxlOBeZQQYbYS6WxSbIA
&redirect_uri=https%3A%2F%2Fclient%2Eexample%2Ecom%2Fcb
```
**E.** The **authorization server** authenticates the **client**, validates the **authorization code**, and *ensures* that the **redirection URI** received matches the URI used to redirect the client in step (C).  If valid, the authorization server responds back with an access token and, optionally, a refresh token.

An example successful response:

```http
HTTP/1.1 200 OK
Content-Type: application/json;charset=UTF-8
Cache-Control: no-store
Pragma: no-cache

{
"access_token":"2YotnFZFEjr1zCsicMWpAA",
"token_type":"example",
"expires_in":3600,
"refresh_token":"tGzv3JOkF0XG5Qx2TlKWIA",
"example_parameter":"example_value"
}
```

### Implicit Grant

The implicit grant type is used to obtain access tokens (it does not
support the issuance of refresh tokens) and is optimized for public
clients **known to operate a particular redirection URI**.  These clients
are **typically implemented in a browser using a scripting language
such as JavaScript**.

Since this is a redirection-based flow, the client must be capable of
interacting with the resource owner's user-agent (typically a web
browser) and capable of receiving incoming requests (via redirection)
from the authorization server.

*Unlike the authorization code grant type, in which the client makes
separate requests for authorization and for an access token, the
client receives the access token as the result of the authorization
request.*

<u>The implicit grant type does not include client authentication, and
relies on the presence of the resource owner and the registration of
the redirection URI.  Because the access token is encoded into the
redirection URI, it may be exposed to the resource owner and other
applications residing on the same device.</u>

#### Architecture

```
```

#### Runtime view

```plantuml
actor "Resource Owner" as resource_owner
participant "User Agent\n(Tipically a **Web Browser**)" as user_agent
participant "Client" as client
participant "Authorization Server" as authorization_server
participant "Web-Hosted Client Resource" as resource_server

user_agent <-- client: A. **Direct** to **Authorization Server**
user_agent -> authorization_server: A. GET URI ?**clientid**=...&\n**redirect_uri**=https://client...&\n**response_type**=**token**&\nscope&state
user_agent <-- authorization_server: A. Render Authorization Page
resource_owner -> user_agent : B. **Resource Owner**\nauthenticates\nand Grants Client 
user_agent -> authorization_server: B. **Resource Owner** Grants **Client** 
user_agent <-- authorization_server: C. **302** to URI **redirect_uri**?**access_token**
user_agent -> resource_server: D. GET **redirect_uri** with **access_token**
user_agent <-- authorization_server: E. Response
user_agent -> client: F: **access_token**
```

**A.** The client initiates the flow by directing the resource owner's user-agent to the authorization endpoint.  The client includes: 
  - **client identifier**
  - **requested scope**
  - **local state**
  - **redirection URI** to which the authorization server will send the user-agent back once access is granted (or denied).

For example, the client directs the user-agent to make the following
HTTP request using TLS (with extra line breaks for display purposes
only):

```http
GET /authorize?response_type=token&client_id=s6BhdRkqt3&state=xyz&redirect_uri=https%3A%2F%2Fclient%2Eexample%2Ecom%2Fcb HTTP/1.1
Host: server.example.com
```

**B.** The **authorization server** authenticates the **resource owner** (via the user-agent) and establishes whether the resource owner grants or denies the **client**'s access request.

**C.**  Assuming the **resource owner** grants access, the authorization server redirects the **user-agent** back to the client using the redirection URI provided earlier.  The redirection URI includes the **access token** in the URI fragment.

For example, the authorization server redirects the user-agent by
sending the following HTTP response (with extra line breaks for
display purposes only):

```http
HTTP/1.1 302 Found
Location: http://example.com/cb#access_token=2YotnFZFEjr1zCsicMWpAA &state=xyz&token_type=example&expires_in=3600
````

**D.**  The user-agent follows the redirection instructions by making a request to the web-hosted client resource (which does not include the fragment per [RFC2616]).  The user-agent retains the fragment information locally.

**E.** The web-hosted client resource returns a web page (typically an HTML document with an embedded script) capable of accessing the full redirection URI including the fragment retained by the user-agent, and extracting the access token (and other parameters) contained in the fragment.

**F.**  The user-agent executes the script provided by the web-hosted
    client resource locally, which extracts the access token.

**G.**  The user-agent passes the access token to the client.

### Resource Owner Password Credentials Grant

The resource owner password credentials grant type is suitable in cases where the **resource owner has a trust relationship with the client, such as the device operating system or a highly privileged application**.  The authorization server should take special care when enabling this grant type and only allow it when other flows are not viable.

This grant type is suitable for clients capable of obtaining the resource owner's credentials (username and password, typically using an interactive form).  It is also used to migrate existing clients using direct authentication schemes such as HTTP Basic or Digest authentication to OAuth by converting the stored credentials to an access token.

#### Architecture

```
     +----------+
     | Resource |
     |  Owner   |
     |          |
     +----------+
          v
          |    Resource Owner
         (A) Password Credentials
          |
          v
     +---------+                                  +---------------+
     |         |>--(B)---- Resource Owner ------->|               |
     |         |         Password Credentials     | Authorization |
     | Client  |                                  |     Server    |
     |         |<--(C)---- Access Token ---------<|               |
     |         |    (w/ Optional Refresh Token)   |               |
     +---------+                                  +---------------+
```

#### Runtime view

```plantuml
actor "Resource Owner" as resource_owner
participant "Client" as client
participant "Authorization Server" as authorization_server
resource_owner -> client: A.
client -> authorization_server: B.
client <-- authorization_server: C.
```

**A**. The resource owner provides the client with its username and password.

**B**.  The client requests an access token from the authorization server's token endpoint by including the credentials received from the resource owner.  When making the request, the client authenticates with the authorization server.

```http
POST /token HTTP/1.1
Host: server.example.com
Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW
Content-Type: application/x-www-form-urlencoded

grant_type=password&username=johndoe&password=A3ddj3w
```
**C**.  The authorization server authenticates the client and validates the resource owner credentials, and if valid, issues an access token.

An example successful response:

```http
HTTP/1.1 200 OK
Content-Type: application/json;charset=UTF-8
Cache-Control: no-store
Pragma: no-cache

{
"access_token":"2YotnFZFEjr1zCsicMWpAA",
"token_type":"example",
"expires_in":3600,
"refresh_token":"tGzv3JOkF0XG5Qx2TlKWIA",
"example_parameter":"example_value"
}
```

### Client Credentials Grant

The client can request an access token using only its client credentials (or other supported means of authentication) when the client is requesting access to the protected resources under its control, or those of another resource owner that have been previously arranged with the authorization server (the method of which is beyond the scope of this specification).

#### Architecture
```
     +---------+                                  +---------------+
     |         |                                  |               |
     |         |>--(A)- Client Authentication --->| Authorization |
     | Client  |                                  |     Server    |
     |         |<--(B)---- Access Token ---------<|               |
     |         |                                  |               |
     +---------+                                  +---------------+
```
#### Runtime view
```plantuml
participant "Client" as client
participant "Authorization Server" as authorization_server
client -> authorization_server: A.
client <-- authorization_server: B.
```

**A**. The client authenticates with the authorization server and requests an access token from the token endpoint.

For example, the client makes the following HTTP request using transport-layer security (with extra line breaks for display purposes only):

```http
POST /token HTTP/1.1
Host: server.example.com
Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
```

**B**. The authorization server authenticates the client, and if valid, issues an access token.
An example successful response:
```http
HTTP/1.1 200 OK
Content-Type: application/json;charset=UTF-8
Cache-Control: no-store
Pragma: no-cache

{
"access_token":"2YotnFZFEjr1zCsicMWpAA",
"token_type":"example",
"expires_in":3600,
"example_parameter":"example_value"
}
```

