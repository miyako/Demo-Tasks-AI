var $homeFolder : 4D.Folder
$homeFolder:=Folder(fk home folder).folder(".GGUF")
var $file : 4D.File
var $URL : Text
var $port : Integer
var $huggingface : cs.event.huggingface

var $event : cs.event.event
$event:=cs.event.event.new()

$event.onError:=Formula(ALERT($2.message))
$event.onData:=Formula(LOG EVENT(Into 4D debug message; This.file.fullName+":"+String((This.range.end/This.range.length)*100; "###.00%")))
$event.onResponse:=Formula(LOG EVENT(Into 4D debug message; This.file.fullName+":download complete"))
$event.onTerminate:=Formula(LOG EVENT(Into 4D debug message; (["process"; $1.pid; "terminated!"].join(" "))))

$port:=8080

$folder:=$homeFolder.folder("Llama-3-ELYZA-JP-8B")
$path:="Llama-3-ELYZA-JP-8B-Q4_K_M.gguf"
$URL:="keisuke-miyako/Llama-3-ELYZA-JP-8B-gguf-q4_k_m"

var $logFile : 4D.File
$logFile:=$folder.file("llama.log")
$folder.create()
If (Not($logFile.exists))
	$logFile.setContent(4D.Blob.new())
End if 

var $batch_size; $batches; $threads : Integer
$batch_size:=2048
$batches:=2
$threads:=2

var $cores : Integer
$cores:=System info.cores\2

$options:={\
log_file: $logFile; \
ctx_size: $batch_size*$batches*$threads; \
batch_size: $batch_size*$batches; \
parallel: $cores; \
threads: $threads; \
n_predict: -1; \
threads_batch: $threads; \
threads_http: $threads; \
temp: 0.7; \
top_k: 40; \
top_p: 0.9; \
log_disable: False; \
repeat_penalty: 1.1; \
n_gpu_layers: -1}

$huggingface:=cs.event.huggingface.new($folder; $URL; $path)
$huggingfaces:=cs.event.huggingfaces.new([$huggingface])

$llama:=cs.llama.llama.new($port; $huggingfaces; $homeFolder; $options; $event)
