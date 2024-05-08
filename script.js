
// Add event listener to the button element
const uploadButton = document.querySelector('#uploadButton');
uploadButton.addEventListener('click', uploadFiles);

function uploadFiles(event) {
	event.preventDefault();

	const fileInput = document.querySelector('#fileInput');
	const selectedFiles = fileInput.files;

	const formData = new FormData();

	for (const selectedFile of selectedFiles) {
		// Console.log(selectedFiles[i]);
		uploadReplay(selectedFile);
	}
}

function userlog(text) {
	document.querySelector('#userlog').innerHTML += text + '</br>';
}

function uploadReplay(file) {
	const request = new XMLHttpRequest();
	request.addEventListener('readystatechange', () => {
		if (request.readyState === XMLHttpRequest.DONE) {
			if (request.status === 200) {
				userlog(file.name + ' uploaded successfully!');
			} else {
				userlog(file.name + ' failed to upload!');
			}
		}
	});

	const url = 'https://tm.0cx.de/upload/replay';

	request.open('POST', url, true);
	request.withCredentials = true;

	// request.setRequestHeader('User-Agent', 'Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0');
	request.setRequestHeader('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8');
	request.setRequestHeader('Accept-Language', 'en-US,en;q=0.5');
	request.setRequestHeader('Content-Type', 'multipart/form-data; boundary=---------------------------86198276832215236822279235129');

	const fr = new FileReader();
	fr.addEventListener('load', () => {
		const s1 = document.querySelector('#sessionid').value;
		const s2 = document.querySelector('#mxclientauth').value;

		document.cookie = 'ASP.NET_SessionId='.concat(s1, '; samesite=lax;');
		document.cookie = '.mxclientauth='.concat(s2, '; samesite=lax');

		const requestParts = [
		'-----------------------------86198276832215236822279235129\r\nContent-Disposition: form-data; name="replay_file"; filename="',
			file.name,
		'"\r\nContent-Type: application/octet-stream\r\n\r\n',
			fr.result,
		'\r\n-----------------------------86198276832215236822279235129--\r\n'
		];

		postData = ''.concat(...requestParts);

		request.send(postData);
	});

	const gbxContent = fr.readAsBinaryString(file);
}
