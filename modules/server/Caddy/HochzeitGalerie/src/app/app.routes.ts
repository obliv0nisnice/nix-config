import { Routes } from '@angular/router';
import { AuthorizedComponent } from './component/authorized/authorized.component';
import { UnauthorizedComponent } from './component/unauthorized/unauthorized.component';
import { AuthGuard } from './auth.guard';

export const routes: Routes = [
  { path: '', component: AuthorizedComponent, canActivate: [AuthGuard] },
  { path: 'unauthorized', component: UnauthorizedComponent },
  { path: '**', redirectTo: 'unauthorized' }
];
