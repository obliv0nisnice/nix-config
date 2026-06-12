import {Component, ElementRef, Output, ViewChild} from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../auth.service';
import { FormsModule } from '@angular/forms';
import {CommonModule, DOCUMENT} from "@angular/common";
import "jquery";


@Component({
  selector: 'app-login',
  standalone: true,
  imports: [
    FormsModule,
    CommonModule
  ],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {
  username: string = "";
  password: string = "";
  errorMessage: string | undefined;



  constructor(private authService: AuthService, private router: Router) {}

  login($event: MouseEvent): void {
    this.authService.login({ username: this.username, password: this.password }).subscribe(
      (response: any) => {
        localStorage.setItem('token', response.token);
        localStorage.setItem('currentUser', this.username);
        this.router.navigate(['/home']);
      },
      (error: any) => {
        console.error('Login failed:', error);
        // Handle login failure, e.g., show error message
      }
    );
  }



  protected readonly onclose = onclose;
}
