# Rainiel Ryan L. Necio, IT Student
## INF233
## CTADMOBL Advance Mobile Programming

A Flutter Project that focuses on advanced topics covering web to mobile transactions

## Lab Activity Instance

## Lab Activity 1: discussion

setState is best for ephemeral or local UI state that belongs to a single widget, such as a counter on one screen, because it only rebuilds that widget’s subtree when the value changes. Provider is better for app-wide or shared state that many screens need, like a light and dark theme, since the data lives outside individual widgets and can be read from anywhere in the tree. With setState, state is tied to a StatefulWidget and is lost when that widget is disposed, while Provider keeps state in a model (for example ChangeNotifier) that survives navigation between screens. Provider also reduces the need to pass data through many constructors, which makes larger apps easier to maintain. In short, we use setState for simple, temporary UI updates and use Provider when the same state must stay consistent across the whole application.

## Lab Activity 2: discussion

In this activity, the model, service, and screen work together to render data from an API endpoint. The Product model defines the shape of each item and converts JSON into Dart objects through fromJson. The ProductService handles the network call by reading the HOST from the .env file, sending a GET request to the products endpoint, decoding the response, and returning a list of Product models. The ProductScreen then uses that service in initState, stores the result in a Future, and uses FutureBuilder to show loading, error, or the product grid depending on the result, so the UI only displays data and never talks to the API directly.

This activity introduces a layered Model–Service–UI design pattern based on separation of concerns. Networking and parsing stay in the service and model, while the screen focuses on presentation and user interaction such as search and the details popup. That makes the app easier to maintain because we can change the API host or response format without rewriting the whole UI, and it keeps Provider for shared theme state while API data is loaded asynchronously through the service.

## Lab Activity 3: discussion

In this activity, the Cart model, CartService, and CartScreen work together to render one user’s cart from the API, and tapping an item opens the shared detail_screen. The Cart model converts JSON into Dart objects, while CartService reads HOST and USER_ID from .env and uses a get-by-id style call, GET /carts/user/:id, so only that user’s cart is loaded instead of every cart. CartScreen then displays those items through Provider, and a tap reuses DetailScreen to show the selected product’s price, quantity, and discount. This updates the Model–Service–UI pattern by sharing one detail screen across routes and keeping cart state in the service, so fetching by id, adding to cart, and showing details stay separate from the UI.

## Lab Activity 4: discussion

In this activity, the User model, UserService, and ProfileScreen work together to show the logged-in account after the login API runs. UserService posts credentials to /auth/login, maps the JSON into a User model, and saves that user in SharedPreferences, then ProfileScreen reads getUser() and only displays the name, email, gender, and id. This updates the Model–Service–UI pattern by adding a session layer: splash checks isLoggedIn(), sign-in persists the user, and profile renders saved data instead of calling the API again. CartScreen uses that saved user id so CartService can call GET /carts/user/:id and POST /carts/add for the same person, which keeps the cart tied to the logged-in user instead of a hardcoded id.

## Lab Activity 5: discussion

In this activity, sign-in and sign-up both go through UserService, but they use different backends. DummyJSON sign-in still posts a username and password to /auth/login and saves the user in SharedPreferences, while sign-up collects the user fields, tries POST /users/add, and then creates a real account with Firebase Auth using email and password. The main idea of UserService is to hide that choice from the screens: they call methods such as loginUser, signIn, createAccount, updateUsername, and deleteAccount, and the service decides whether the data comes from the API or from the Firebase Auth SDK. ProfileScreen then reads getUserData() and shows the details for that login type, including update username, change password, delete account, and logout back to the login screen. Firebase benefits this app because the account is actually stored, with token refresh and account security handled by the SDK, while the UI keeps the same Model–Service–UI pattern.

