Class {
	#name : 'FBParallelJoinNodeBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'execution' }
FBParallelJoinNodeBehavior >> execute [
	"neither the fork's own activation nor this join's own activation ever reached #done:
	FBParallelExecutor>>continue's own '(self activationOf: node) done. self stop' tail is
	only reached when nothing ever pops this executor first - but a join always pops it
	directly via #popThenResume: once #atEnd, bypassing that tail entirely. Mirror
	FBTaskBehavior>>execute's value/done/followAllOutgoing order for both activations here
	instead - #done is itself a no-op (see FBParallelActivation>>done) until the executor is
	truly at its last index, so this is safe to call unconditionally, exactly like a plain
	task's activation already does on every iteration."
	| executor |
	executor := activation flowInstance executor.
	executor atEnd ifTrue: [
		executor popThenResume: [
			(executor activationOf: executor node) done.
			activation values: activation arguments.
			activation done.
			activation followAllOutgoing ] ]
]
