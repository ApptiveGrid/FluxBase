"
I am a deferred choice (WCP-16; BPMN's event-based gateway): a split whose branches each
lead into a waiting spot - a condition wait, a trigger target such as a form, a remote
flow - and of which exactly one goes on: the first one whose wait is resumed. The others
fall the moment the choice is decided - queued or parked, in this instance or in a sub
flow a branch called - the way a cancelled strand falls (FBFlowInstance>>
decideDeferredChoice:wonBy:), and an FBDeferredChoiceDecided records which branch won.
Behind me the branches may merge or end on their own; only the winner ever gets there.

The decision is made where a wait goes on, FBBaseExecutor>>resume:withToken:value: - the
one continuation path - and by a condition wait whose condition already holds when it is
entered (FBWaitForConditionBehavior). There is no tie: the engine is single-threaded, the
first impulse wins, and a second one finds its wait gone and is silent, like a double
submit.

Every branch has to lead into a node that parks (FBNode>>parksOnEntry); a branch that
would run at once cannot take part in a choice, since steps run to rest before any impulse
from outside arrives, and my behavior refuses such a model. I open a pass like every
split (FBSplitExecution), which is what remembers whether I was decided and where my
branches began (#origin).

Abstract in the sense of the exposed node set only, like FBRemoteFlowTask and
FBTerminateEvent: ApptiveGrid lists every non-abstract node class to its client as a type
a user can pick, and the client knows nothing of a choice yet. Instantiable all the same;
the tests build me directly. An ApptiveBase subclass lifts this once the client can show
and configure one.
"
Class {
	#name : 'FBDeferredChoice',
	#superclass : 'FBSplitGateway',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBDeferredChoice class >> isAbstract [
	"see the class comment: out of the exposed node set until the client knows the node"
	^ true
]

{ #category : 'instance creation' }
FBDeferredChoice class >> typeName [
	^ #deferredChoice
]

{ #category : 'accessing' }
FBDeferredChoice >> defaultBehaviorClass [
	^ FBDeferredChoiceBehavior
]

{ #category : 'testing' }
FBDeferredChoice >> isDeferredChoice [
	^ true
]
