# Little Wonder - Mini ToDo List App for iPhone and iPad (Universal binary)

## What you can do:
- Create a task
- Re-order tasks
- List up done tasks
- Delete a task

## Limitation
- User can have MAX_TODO_COUNT todos only (currently set to 200)

## ToDo data model to support re-order in an efficient way:
- Each Task has 'float' priority
- re-order a task is done by changing its priority such as new_prio = (last lower prio + next higher prio)/2
- if a task is re-ordered, we do not need to update other tasks, we can change just the target task, and notify it to the server. In this way, we can save network traffics
- Comparing with 'linked-list'-based approaches, it is probably more robust against data corruption.

## Resolving conflicts between server and local data objects
- If a todo is modified by user (text, order, done state changes and deleted) then it will be marked as 'dirty'.
- This app is only for private use. This means that 'dirty' todos should NOT be overwritten by server, but server should alter its data later with dirty todos.
- Clean (dirty = false) todos can be overwritten by server data. This might happen in the future, for example, when we provide 'share' functionality
- Rule of thumb: given server response, clean todos can be overwritten, but dirty todos should NOT be overwritten.
- We define a conflict such that we've got data for a todo, which is marked as dirty.
- Resolving conflict of todo text is easy: do not modify it.
- Resolving conflicts of priority and done state are complicated. The app has an algorithm to solve those problems

## Resolving priority and done state conflicts:
1. Fetch all todos, which are not done yet, and store them in an array (sorted by prios ascend.)
2. Create an empty list for dirty todos
3. For each todo in the array:
  1. if the todo is clean, then update its data with server response.
    - updated todo should be removed from server response dictionary.
    - if not, store it in dirty todo list.
4. For each todo in dirty todo list:
  1. find lower bound of prio
    - if the todo is on head, then assume that lower bound is 0.
    - if last lower todo in all-todo-list is clean, then pick it up as last lower todo.
    - if not, pick previous one in dirty todo list.
  2. find upper bound of prio
    - traverse all-todo-list in tail direction until find a next clean todo. pick it up as next higher todo
    - if no clean todo is found, then assume upper bound of prio is round(lower bound)+1
  3. set target todo's prio with avg. of lower and upper bounds.
  4. remove the target todo from server response dictionary
5. For a list of done todos: Do 1-4 with remaining server response
6. Remaining todos in server response dictionary are new todos. Add them into local DB.
7. Done

- Time complexity: O(N) ~ O(N^2)
- Space complexity: O(N)

## Misc.
- In order to use device's network resources efficiently, we track last network requests and cancel them if necessary.

## Notes:
- supporting iOS 9.0 or later
- open in Xcode 7 to compile the project
- no external libs, no cocoapods for the app. OCMock as mocking framework.

