require 'json'

# Inputs

intents = %w(
	getRandomNewscast
	AMAZON.PauseIntent
	AMAZON.ResumeIntent
	AMAZON.CancelIntent
	AMAZON.LoopOffIntent
	AMAZON.LoopOnIntent
	AMAZON.NextIntent
	AMAZON.PreviousIntent
	AMAZON.RepeatIntent
	AMAZON.ShuffleOffIntent
	AMAZON.ShuffleOnIntent
	AMAZON.StartOverIntent
	AMAZON.HelpIntent
)

# Alexa, ask //skill title// to…
utterances = {
	getRandomNewscast: [
		"play a newscast",
		"give me a newscast",
		"play some headlines",
		"play me the news",
		"give me some news",
		"play something"
	]
}

# Outputs

intents_output = {
	intents: []
}
intents.each { |intent_name| intents_output[:intents] << { intent: intent_name } }

utterances_output = utterances.map do |intent, u_values|
	u_values.map {|u| "#{intent} #{u}" }.join("\n")
end.join("\n")

# Render

puts "\n\n---Intents---\n\n"
puts JSON.pretty_generate(intents_output)
puts "\n\n---Utterances---\n\n"
puts utterances_output