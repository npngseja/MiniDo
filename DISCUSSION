- We post dirty data whenever data modification by user happens. We might need to have more intelligent way to sync data over cloud.

- Some process has nested function calls, each of which can be failed. We need a roll-back functionaliy to cancel the failed process (it can happen on Core Data Stack)

- We need more unit tests to cover more errors and edge cases.

- Core Data Stack is working on main thread. It would be better to make it multi-threaded. If we have large

- MAX_TODO_COUNT assumption should be relaxed later. Conflict resolution algorithm assumes that it can access and load all todos on memory. This will be a problem, when we relax the assumption.

- Known Issues:
    - Make a todo text empty in detail view and close the app. Then the todo will appear on the list with 'Type in...' placeholder
