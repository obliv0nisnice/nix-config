import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AdminComponent } from './admin/admin.component';
import { hasRoleGuard } from './has-role.guard';
import { HomeComponent } from './home/home.component';
import { Role } from './role';
import { UnauthorizedComponent } from './unauthorized/unauthorized.component';
import {LoginComponent} from "./login/login.component";
import {RegistrationComponent} from "./registration/registration.component";
import { AuthGuard } from './auth.guard';


export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: 'home', component: HomeComponent },
  {path: "login", component: LoginComponent},
  {path: "registration", component: RegistrationComponent},
  {
    path: 'admin',
    component: AdminComponent,
    canActivate: [hasRoleGuard],
    data: {
      roles: [ Role.ADMIN ]
    }
  },
  { path: 'unauthorized', component: UnauthorizedComponent },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
