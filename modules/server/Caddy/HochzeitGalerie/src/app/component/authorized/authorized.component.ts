import { Component, HostListener, OnInit, ViewChild, TemplateRef } from '@angular/core';
import {HttpClient, HttpEventType} from '@angular/common/http';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { environment } from "../../../environments/environment";
import { CommonModule, NgSwitch } from '@angular/common';


interface UploadedFile {
  type: string;
  url: string;
  width?: number; // Optional für PhotoSwipe
  height?: number;
}

@Component({
  selector: 'app-authorized',
  templateUrl: './authorized.component.html',
  standalone: true,
  imports: [
    NgSwitch, CommonModule,
  ],
  styleUrls: ['./authorized.component.css'],

})
export class AuthorizedComponent implements OnInit {
  selectedFiles: File[] = [];
  uploadedFiles: UploadedFile[] = [];
  errorMessage: string | null = null;
  imageOpacity: number = 1;
  currentFileIndex: number | null = null;
  progress: number = -1;

  @ViewChild('mediaModal') mediaModal!: TemplateRef<any>;

  constructor(private http: HttpClient, private modalService: NgbModal) {}

  ngOnInit(): void {
    this.fetchUploadedFiles();
  }

  @HostListener('window:scroll', [])
  onWindowScroll() {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
    this.imageOpacity = Math.max(1 - scrollTop / 600, 0); // Passe den Wert 300 nach Bedarf an
  }

  onFileSelected(event: any): void {
    this.selectedFiles = Array.from(event.target.files);
    this.errorMessage = null; // Reset error message
  }

  onUpload(): void {
    if (this.selectedFiles.length === 0) {
      this.errorMessage = 'Please select files to upload.';
      return;
    }

    const formData = new FormData();
    this.selectedFiles.forEach(file => {
      formData.append('files', file, file.name);
    });

    this.http.post<{ fileUrls: string[] }>(`${environment.apiUrl}/Upload/upload`, formData, {
      reportProgress: true,
      observe: 'events'
    }).subscribe({
      next: event => {
        if (event.type === HttpEventType.UploadProgress && event.total) {
          this.progress = Math.round((100 * event.loaded) / event.total);
        } else if (event.type === HttpEventType.Response) {
          this.uploadedFiles = event.body?.fileUrls.map(url => ({
            type: this.getFileType(url),
            url
          })) || [];
          this.progress = 0; // Reset progress on successful upload
        }
      },
      error: error => {
        console.error('Upload error', error);
        this.errorMessage = 'An error occurred during file upload. Please try again.';
        this.progress = 0; // Reset progress on error
      }
    });
  }

  private fetchUploadedFiles(): void {
    this.http.get<{ fileUrls: string[] }>(`${environment.apiUrl}/Upload/files`)
      .subscribe({
        next: response => {
          this.uploadedFiles = response.fileUrls.map(url => ({
            type: this.getFileType(url),
            url
          }));
        },
        error: error => {
          console.error('Fetch uploaded files error', error);
          this.errorMessage = 'An error occurred while fetching uploaded files. Please try again.';
        }
      });
  }





  get currentFile(): UploadedFile | null {
    if (this.currentFileIndex !== null) {
      return this.uploadedFiles[this.currentFileIndex];
    }
    return null;
  }

  open(file?: UploadedFile) {
    if (file) {
      this.currentFileIndex = this.uploadedFiles.indexOf(file);
    } else {
      this.currentFileIndex = null;
    }
    this.modalService.open(this.mediaModal);
  }

  prevFile(): void {
    if (this.currentFileIndex !== null && this.currentFileIndex > 0) {
      this.currentFileIndex--;
    }
  }

  nextFile(): void {
    if (this.currentFileIndex !== null && this.currentFileIndex < this.uploadedFiles.length - 1) {
      this.currentFileIndex++;
    }
  }

  hasNext(): boolean {
    return this.currentFileIndex !== null && this.currentFileIndex < this.uploadedFiles.length - 1;
  }

  hasPrevious(): boolean {
    return this.currentFileIndex !== null && this.currentFileIndex > 0;
  }
  private getFileType(url: string): string {
    const extension = url.split('.').pop()?.toLowerCase();
    if (['mp4', 'mov'].includes(extension!)) {
      return 'video';
    }
    if (['jpg', 'jpeg', 'png'].includes(extension!)) {
      return 'image';
    }
    return 'unknown'; // Handle unexpected file types
  }

  protected readonly name = name;
}
