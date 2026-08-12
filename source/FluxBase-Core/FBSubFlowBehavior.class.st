Class {
	#name : 'FBSubFlowBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core',
	#package : 'FluxBase-Core'
}

{ #category : 'private' }
FBSubFlowBehavior >> buildChildScope [
    "answer a new scope for the sub flow call, one level deeper than the calling flow
    instance's scope. signals FBSubFlowMaxDepthExceeded if that would exceed the node's
    configured maxDepth.

    creates the caller's root scope if it has none yet, which is the case for the
    outermost instance up to its first sub flow call. that write lives here rather than
    in a lazy FBFlowInstance>>scope getter for one reason: this is the first moment a
    scope is actually needed, and it is reached from a node activation, so a write
    transaction is guaranteed - whereas a plain read of #scope can happen in a read-only
    one, where assigning signals SoilWriteOnReadOnlyTransaction"
    | instance parentScope |
    instance := activation flowInstance.
    parentScope := instance scope.
    parentScope ifNil: [
        parentScope := FBScope rootOwnedBy: nil.
        instance scope: parentScope ].
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
