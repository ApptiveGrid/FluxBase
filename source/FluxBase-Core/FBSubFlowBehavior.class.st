Class {
	#name : 'FBSubFlowBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core',
	#package : 'FluxBase-Core'
}

{ #category : 'private' }
FBSubFlowBehavior >> buildChildScope [
    "answer a new scope for the sub flow call, one level deeper than the calling flow instance's current scope. signals FBSubFlowMaxDepthExceeded if that would exceed the node's configured maxDepth"
    | parentScope |
    parentScope := activation flowInstance scope.
    parentScope depth + 1 > self node maxDepth
        ifTrue: [ FBSubFlowMaxDepthExceeded signal: 'sub flow call depth exceeds maximum of ', self node maxDepth printString ].
    ^ parentScope childOwnedBy: self node
]

{ #category : 'execution' }
FBSubFlowBehavior >> execute [
    "do not run the sub flow here - only create its instance and push a frame for it
    onto the calling instance's executor stack, exactly like FBParallelNodeBehavior
    pushes a scope instead of looping over it. FBSubFlowExecutor then advances the
    sub flow one node per step, which is what makes a sub flow call steppable from
    the outside and keeps every step - including entering and leaving the sub flow -
    within a single node's transaction. running the child to completion here would
    make one step of the caller span the whole sub flow"
    | childScope childInstance |
    childScope := self buildChildScope.
    childInstance := self node subFlow newInstance.
    childInstance scope: childScope.
    "initialize the child's executor and initial value without executing anything"
    childInstance initialValue: self argument.
    activation flowInstance
        addSubFlowInstance: childInstance;
        pushExecutor: (FBSubFlowExecutor new
                 childInstance: childInstance;
                 callerActivation: activation;
                 yourself)
]
