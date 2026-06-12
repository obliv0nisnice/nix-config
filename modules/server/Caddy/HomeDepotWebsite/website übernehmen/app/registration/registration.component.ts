import { Component, OnInit } from '@angular/core';
import { AuthService } from '../auth.service';
import {FormsModule} from "@angular/forms";
import {CommonModule} from "@angular/common"; // Service to interact with API

@Component({
  selector: 'app-registration',
  templateUrl: './registration.component.html',
  standalone: true,
  imports: [
    FormsModule,
    CommonModule
  ],
  styleUrls: ['./registration.component.css']
})
export class RegistrationComponent implements OnInit {
  users: any[] = [];
  username: string = '';
  password: string = '';
  role: string = '';
  registrationMessage: string = '';

  constructor(private authService: AuthService) {}

  ngOnInit(): void {
    this.loadUsers();
  }

  loadUsers(): void {
    this.authService.getUsers().subscribe((data: any) => {
      this.users = data;
    });
  }

  register(): void {
    this.authService.register({ username: this.username, password: this.password, role: this.role }).subscribe({
      next: (response: any) => {
        this.registrationMessage = response.message;
        this.loadUsers();
        this.username = '';
        this.password = '';
        this.role = '';
      },
      error: (err: any) => {
        if (err.error && err.error.message) {
          this.registrationMessage = err.error.message;
        } else {
          this.registrationMessage = 'Registration failed. Please try again later.';
        }
        console.error('Registration failed', err);
      }
    });
  }


}
