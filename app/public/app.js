document.getElementById('uploadBtn').addEventListener('click', uploadImage);

async function uploadImage() {
  const file   = document.getElementById('fileInput').files[0];
  const btn    = document.getElementById('uploadBtn');
  const status = document.getElementById('status');

  if (!file) { alert('Please select an image first.'); return; }

  btn.disabled       = true;
  status.textContent = 'Uploading...';

  try {
    const formData = new FormData();
    formData.append('image', file);

    const res  = await fetch('/upload', { method: 'POST', body: formData });
    const data = await res.json();

    status.textContent = 'Uploaded: ' + data.s3_key;
    await loadImages();
  } catch (err) {
    status.textContent = 'Upload failed: ' + err.message;
  } finally {
    btn.disabled = false;
  }
}

async function loadImages() {
  try {
    const res    = await fetch('/images');
    const images = await res.json();

    const html = images.map((img) => `
      <div class="card">
        <img src="${img.url}" alt="${img.filename}" />
        <div class="card-info">
          <div class="filename">${img.filename}</div>
          <div class="meta">${(img.size / 1024).toFixed(1)} KB</div>
          <div class="meta">${new Date(img.uploaded_at).toLocaleString()}</div>
        </div>
      </div>
    `).join('');

    document.getElementById('gallery').innerHTML = html || '<p>No images yet.</p>';
  } catch {
    document.getElementById('gallery').innerHTML = '<p>Could not load images.</p>';
  }
}

loadImages();
