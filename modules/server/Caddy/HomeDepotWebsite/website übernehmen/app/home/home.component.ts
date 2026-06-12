import {Component, OnInit} from '@angular/core';
import {Router} from "@angular/router";
import {FormsModule} from "@angular/forms";
import {CommonModule} from "@angular/common";
import { AuthService } from '../auth.service';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [FormsModule,
    CommonModule],
  templateUrl: './home.component.html',
  styleUrl: './home.component.css'
})
export class HomeComponent implements OnInit{
  isAdmin: boolean = false;
  currentUser: string = "" ;
  currentToken: string = "";
  currentRole: string = "";

  constructor(private authService: AuthService, private router: Router) {}

  ngOnInit(): void {
    this.currentUser = localStorage.getItem('currentUser') || '';
    this.currentToken = localStorage.getItem('token') || '';
    this.authService.getUserRole().subscribe(
      (response) => {
        this.currentRole = response.role; // Annahme: Die Rolle wird als 'role' im Response zurückgegeben
        this.isAdmin = this.currentRole === 'admin'; // Beispiel: isAdmin abhängig von der Rolle
      },
      (error) => {
        console.error('Error fetching user role:', error);
      }
    );
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
  navigateToRegistration(): void {
    this.router.navigate(['/registration']);
  }
}
