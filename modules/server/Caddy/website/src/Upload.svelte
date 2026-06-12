<script>

    let file = null;
    let uploadResponse = '';

    const handleFileChange = (event) => {
        file = event.target.files[0];
    };

    const handleSubmit = async () => {
        if (!file) {
            alert('Please select a file');
            return;
        }

        const formData = new FormData();
        formData.append('file', file);

        const response = await fetch('http://localhost:5000/api/upload', {
            method: 'POST',
            body: formData,
        });

        if (response.ok) {
            const result = await response.json();
            uploadResponse = `File uploaded successfully: ${result.filePath}`;
        } else {
            uploadResponse = 'File upload failed';
        }
    };
</script>

<main class="container mt-5">
    <h1>File Upload</h1>
    <form on:submit|preventDefault={handleSubmit}>
        <div class="mb-3">
            <label for="file" class="form-label">Choose file</label>
            <input type="file" class="form-control" id="file" on:change={handleFileChange} required>
        </div>
        <button type="submit" class="btn btn-primary">Upload</button>
    </form>
    {#if uploadResponse}
        <div class="mt-3 alert alert-info">{uploadResponse}</div>
    {/if}
</main>
