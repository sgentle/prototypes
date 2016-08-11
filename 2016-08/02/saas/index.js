var aws = require('aws-sdk');
var fs = require('fs');
var s3 = new aws.S3();
var exec = require('child_process').execFile;

exports.handler = (event, context, callback) => {
  console.log("Reading options from event:\n", event);

  var srcBucket = 'steinberg-in';
  var key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "));
  var destBucket = 'steinberg-out';

  var ext = key.split('.').slice(-1);

  var inFile = '/tmp/' + Math.random().toFixed(10).slice(2) + '.' + ext;
  var outFile = '/tmp/' + Math.random().toFixed(10).slice(2) + '.png';

  var getReq = s3.getObject({
    Bucket: srcBucket,
    Key: key
  });
  var srcStream = getReq.createReadStream();
  var writeStream = fs.createWriteStream(inFile);

  new Promise((resolve, reject) => {
    console.log("Piping stream to", inFile);
    srcStream.on('error', reject);
    srcStream.pipe(writeStream);
    writeStream.on('finish', () => {
      console.log("Calling ./whynotsteinberg", inFile, outFile);
      exec('./whynotsteinberg', [inFile, outFile], (err, stdout, stderr) => {
        if (err) return reject(new Error(stderr));
        resolve();
      });
    });
  })
  .then(() => console.log("Uploading"))
  .then(() => s3.putObject({
    Bucket: destBucket,
    Key: key,
    Body: fs.createReadStream(outFile),
    ContentType: 'image/png'
  }).promise())
  .then(() => console.log("Finished"))
  .then(() => callback(), callback);
};
