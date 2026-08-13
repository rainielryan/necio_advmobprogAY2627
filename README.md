# Rainiel Ryan L. Necio, IT Student
## INF233
## CTADMOBL Advance Mobile Programming

A Flutter Project that focuses on advanced topics covering web to mobile transactions

## Lab Activity Instance

## Discussion: setState vs Provider

setState is best for ephemeral or local UI state that belongs to a single widget, such as a counter on one screen, because it only rebuilds that widget’s subtree when the value changes. Provider is better for app-wide or shared state that many screens need, like a light and dark theme, since the data lives outside individual widgets and can be read from anywhere in the tree. With setState, state is tied to a StatefulWidget and is lost when that widget is disposed, while Provider keeps state in a model (for example ChangeNotifier) that survives navigation between screens. Provider also reduces the need to pass data through many constructors, which makes larger apps easier to maintain. In short, we use setState for simple, temporary UI updates and use Provider when the same state must stay consistent across the whole application.

