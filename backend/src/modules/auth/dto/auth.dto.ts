import { IsEmail, IsNotEmpty, MinLength, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'user@plaza.app' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'Password123' })
  @MinLength(6)
  password: string;

  @ApiProperty({ example: 'Gopi Ganesh' })
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: '+91 98765 43210', required: false })
  @IsOptional()
  phone?: string;

  @ApiProperty({ example: 'Hyderabad', required: false })
  @IsOptional()
  city?: string;
}

export class LoginDto {
  @ApiProperty({ example: 'user@plaza.app' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'Password123' })
  @IsNotEmpty()
  password: string;
}
