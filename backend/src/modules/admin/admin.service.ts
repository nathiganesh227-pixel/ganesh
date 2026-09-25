import { Injectable } from '@nestjs/common';

@Injectable()
export class AdminService {
  getHealth() {
    return {
      admin: true,
    };
  }
}
