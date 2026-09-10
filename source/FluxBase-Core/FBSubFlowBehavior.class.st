Class {
	#name : 'FBSubFlowBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core',
	#package : 'FluxBase-Core'
}

{ #category : 'private' }
FBSubFlowBehavior >> buildChildScope [
    "answer a new scope for the sub flow call, nested in the scope the calling activation
    runs in - an iteration's scope when the call sits inside a parallel node, the
    caller's root scope otherwise. Signals FBSubFlowMaxDepthExceeded if that would exceed
    the node's configured maxDepth, counted in calls (FBScope>>callDepth), not in
    nesting: iterations nest scopes without being calls.

    An instance persisted before tokens carried a scope has none on its activation's
    token; it gets its root scope now - this is a node activation, so a write
    transaction is guaranteed, see FBFlowInstance>>ensureScope"
    | parentScope |
    parentScope := activation token scope ifNil: [ activation flowInstance ensureScope ].
    parentScope callDepth + 1 > self node maxDepth
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
    "the child's first token descends from this activation's, so that a waiting spot
    reserved out here - a link that went into a mail - is reached inside the sub flow"
    childInstance descendFrom: activation token.
    activation flowInstance
        addSubFlowInstance: childInstance;
        pushExecutor: (FBSubFlowExecutor new
                 childInstance: childInstance;
                 callerActivation: activation;
                 yourself)
]
