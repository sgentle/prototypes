Nsolvejs = require 'nsolvejs'

ITERATIONS = 10

bench = (setup, run, n) ->
  data = setup n
  times = for [1..ITERATIONS]
    time = process.hrtime()
    run data
    diff = process.hrtime(time)
    diff[1] / 1000 + diff[0] * 1000000 #Microseconds
  vals = times.reduce ((a, b) -> a + b)
  vals / times.length

# curves =
#   exponential: (a, b) ->
format = (fit) ->
  p = fit.fitParamsUsed.map (x) -> x.toFixed(2)
  switch fit.fitUsed
    when 'polynomial'
      "#{p[2]}x^2 + #{p[1]}x + #{p[0]}"
    else
      "#{fit.fitUsed}: #{p.join ','}"


module.exports = (setup, run) ->
  results = []
  n = 1
  time = 0
  while time < 100000
    # console.log "n", n, "time", time
    time = bench(setup, run, n)
    results.push [n, time]
    n *= 2

  # console.log "results", results
  fit = Nsolvejs.fit.best(results)
  # console.log fit
  format fit
